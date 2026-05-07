-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New query)

-- ── Extensions ──────────────────────────────────────────────────────────────
create extension if not exists "pgcrypto";

-- ── Profiles ────────────────────────────────────────────────────────────────
create table if not exists profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  username     text unique,
  currency     text not null default 'USD',
  credit_score integer not null default 100 check (credit_score between 0 and 100),
  created_at   timestamptz not null default now()
);

-- Auto-create profile row when a user signs up
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into profiles (id, display_name, username)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', ''),
    new.raw_user_meta_data->>'username'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ── Transactions ─────────────────────────────────────────────────────────────
create table if not exists transactions (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  type       text not null check (type in ('income','expense')),
  category   text not null,
  account    text not null,
  amount     numeric(12,2) not null check (amount > 0),
  note       text,
  date       date not null default current_date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- ── Friendships ──────────────────────────────────────────────────────────────
-- One row per direction is fine; queries use OR on both columns.
create table if not exists friendships (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  friend_id  uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, friend_id),
  check (user_id <> friend_id)
);

-- ── Debts ────────────────────────────────────────────────────────────────────
-- direction is from owner_id's perspective:
--   'lend'   → owner lent money to counterpart (counterpart owes owner)
--   'borrow' → owner borrowed from counterpart (owner owes counterpart)
create table if not exists debts (
  id             uuid primary key default gen_random_uuid(),
  owner_id       uuid not null references auth.users(id) on delete cascade,
  counterpart_id uuid not null references auth.users(id) on delete cascade,
  direction      text not null check (direction in ('lend','borrow')),
  amount         numeric(12,2) not null check (amount > 0),
  description    text,
  status         text not null default 'pending'
                   check (status in ('pending','active','settled')),
  deadline       date,
  settled_at     timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  deleted_at     timestamptz
);

-- ── Inbox items ───────────────────────────────────────────────────────────────
-- Payload shapes:
--   friend_request:    {}
--   debt_request:      {"debt_id": "<uuid>"}
--   settlement_request:{"debt_ids": ["<uuid>", ...]}
create table if not exists inbox_items (
  id           uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references auth.users(id) on delete cascade,
  sender_id    uuid not null references auth.users(id) on delete cascade,
  type         text not null
                 check (type in ('friend_request','debt_request','settlement_request')),
  payload      jsonb not null default '{}',
  status       text not null default 'pending'
                 check (status in ('pending','accepted','declined')),
  created_at   timestamptz not null default now()
);

-- Credit score events
-- Date-only deadlines are treated as end-of-day UTC. A missed deadline begins
-- at midnight UTC on the day after the deadline date.
create table if not exists credit_score_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  debt_id uuid not null references debts(id) on delete cascade,
  event_type text not null check (
    event_type in ('missed_deadline', 'overdue_day', 'on_time_settlement')
  ),
  points integer not null,
  event_date date not null default current_date,
  created_at timestamptz not null default now()
);

create unique index if not exists credit_score_events_once_per_debt_idx
  on credit_score_events (debt_id, event_type)
  where event_type in ('missed_deadline', 'on_time_settlement');

create unique index if not exists credit_score_events_daily_idx
  on credit_score_events (debt_id, event_type, event_date)
  where event_type = 'overdue_day';

create or replace function debt_borrower_id(
  owner_id uuid,
  counterpart_id uuid,
  direction text
)
returns uuid
language sql
immutable
as $$
  select case
    when direction = 'lend' then counterpart_id
    else owner_id
  end;
$$;

create or replace function prevent_direct_credit_score_update()
returns trigger
language plpgsql
as $$
begin
  if new.credit_score is distinct from old.credit_score
     and current_user in ('anon', 'authenticated') then
    raise exception 'credit_score cannot be updated directly';
  end if;

  return new;
end;
$$;

drop trigger if exists prevent_direct_credit_score_update_trigger on profiles;
create trigger prevent_direct_credit_score_update_trigger
  before update on profiles
  for each row execute function prevent_direct_credit_score_update();

create or replace function apply_credit_score_event(
  p_user_id uuid,
  p_debt_id uuid,
  p_event_type text,
  p_points integer,
  p_event_date date
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_id uuid;
begin
  insert into credit_score_events (
    user_id,
    debt_id,
    event_type,
    points,
    event_date
  )
  values (
    p_user_id,
    p_debt_id,
    p_event_type,
    p_points,
    p_event_date
  )
  on conflict do nothing
  returning id into inserted_id;

  if inserted_id is null then
    return false;
  end if;

  update profiles
  set credit_score = greatest(0, least(100, credit_score + p_points))
  where id = p_user_id;

  return true;
end;
$$;

create or replace function apply_overdue_credit_penalties(
  p_now timestamptz default now()
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  debt_row debts%rowtype;
  borrower uuid;
  due_at timestamptz;
  full_overdue_days integer;
  day_offset integer;
  events_applied integer := 0;
  request_user_id uuid := auth.uid();
begin
  for debt_row in
    select *
    from debts
    where status = 'active'
      and deadline is not null
      and deleted_at is null
      and (
        request_user_id is null
        or owner_id = request_user_id
        or counterpart_id = request_user_id
      )
  loop
    due_at := ((debt_row.deadline + 1)::timestamp at time zone 'UTC');

    if p_now >= due_at then
      borrower := debt_borrower_id(
        debt_row.owner_id,
        debt_row.counterpart_id,
        debt_row.direction
      );

      if apply_credit_score_event(
        borrower,
        debt_row.id,
        'missed_deadline',
        -5,
        debt_row.deadline
      ) then
        events_applied := events_applied + 1;
      end if;

      full_overdue_days := floor(
        extract(epoch from (p_now - due_at)) / 86400
      )::integer;

      if full_overdue_days > 0 then
        for day_offset in 1..full_overdue_days loop
          if apply_credit_score_event(
            borrower,
            debt_row.id,
            'overdue_day',
            -1,
            (debt_row.deadline + day_offset)
          ) then
            events_applied := events_applied + 1;
          end if;
        end loop;
      end if;
    end if;
  end loop;

  return events_applied;
end;
$$;

create or replace function settle_debts_with_credit_scoring(
  debt_ids_input uuid[],
  p_settled_at timestamptz default now()
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  debt_row debts%rowtype;
  borrower uuid;
  current_user_id uuid := auth.uid();
  due_at timestamptz;
begin
  perform apply_overdue_credit_penalties(p_settled_at);

  for debt_row in
    select *
    from debts
    where id = any(debt_ids_input)
      and deleted_at is null
      and status <> 'settled'
      and (
        owner_id = current_user_id
        or counterpart_id = current_user_id
      )
  loop
    borrower := debt_borrower_id(
      debt_row.owner_id,
      debt_row.counterpart_id,
      debt_row.direction
    );

    if debt_row.deadline is not null then
      due_at := ((debt_row.deadline + 1)::timestamp at time zone 'UTC');

      if p_settled_at < due_at then
        perform apply_credit_score_event(
          borrower,
          debt_row.id,
          'on_time_settlement',
          3,
          p_settled_at::date
        );
      end if;
    end if;

    update debts
    set status = 'settled',
        settled_at = p_settled_at,
        updated_at = p_settled_at
    where id = debt_row.id;
  end loop;
end;
$$;

-- ── Row-Level Security ────────────────────────────────────────────────────────
alter table profiles     enable row level security;
alter table transactions enable row level security;
alter table friendships  enable row level security;
alter table debts        enable row level security;
alter table inbox_items  enable row level security;
alter table credit_score_events enable row level security;

-- profiles: anyone authenticated can read (needed for user search)
create policy "profiles_read_all"
  on profiles for select
  using (auth.role() = 'authenticated');

create policy "profiles_insert_own"
  on profiles for insert
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on profiles for update
  using (auth.uid() = id);

-- transactions: owner only
create policy "transactions_all_own"
  on transactions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- friendships: visible to either party; insert as user_id
create policy "friendships_select"
  on friendships for select
  using (auth.uid() = user_id or auth.uid() = friend_id);

create policy "friendships_insert"
  on friendships for insert
  with check (auth.uid() = user_id);

create policy "friendships_delete"
  on friendships for delete
  using (auth.uid() = user_id or auth.uid() = friend_id);

-- debts: visible to owner or counterpart
create policy "debts_select"
  on debts for select
  using (auth.uid() = owner_id or auth.uid() = counterpart_id);

create policy "debts_insert"
  on debts for insert
  with check (auth.uid() = owner_id);

create policy "debts_update"
  on debts for update
  using (auth.uid() = owner_id or auth.uid() = counterpart_id);

-- inbox_items: sender or recipient
create policy "inbox_select"
  on inbox_items for select
  using (auth.uid() = recipient_id or auth.uid() = sender_id);

create policy "inbox_insert"
  on inbox_items for insert
  with check (auth.uid() = sender_id);

create policy "inbox_update"
  on inbox_items for update
  using (auth.uid() = recipient_id);

create policy "credit_score_events_select_own"
  on credit_score_events for select
  using (auth.uid() = user_id);

grant execute on function apply_overdue_credit_penalties(timestamptz)
  to authenticated;
grant execute on function settle_debts_with_credit_scoring(uuid[], timestamptz)
  to authenticated;
