-- Credit score support for financial responsibility scoring.
-- Date-only deadlines are treated as end-of-day UTC. A deadline is missed at
-- midnight UTC on the day after the deadline date.

alter table profiles
  add column if not exists credit_score integer not null default 100;

alter table profiles
  alter column credit_score set default 100;

update profiles
set credit_score = 100
where credit_score is null;

update profiles
set credit_score = greatest(0, least(100, credit_score));

alter table profiles
  alter column credit_score set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_credit_score_range'
  ) then
    alter table profiles
      add constraint profiles_credit_score_range
      check (credit_score between 0 and 100);
  end if;
end;
$$;

alter table debts
  add column if not exists settled_at timestamptz;

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

alter table credit_score_events enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'credit_score_events'
      and policyname = 'credit_score_events_select_own'
  ) then
    create policy "credit_score_events_select_own"
      on credit_score_events for select
      using (auth.uid() = user_id);
  end if;
end;
$$;

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

grant execute on function apply_overdue_credit_penalties(timestamptz)
  to authenticated;
grant execute on function settle_debts_with_credit_scoring(uuid[], timestamptz)
  to authenticated;
