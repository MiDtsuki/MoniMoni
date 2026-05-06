-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New query)

-- ── Extensions ──────────────────────────────────────────────────────────────
create extension if not exists "pgcrypto";

-- ── Profiles ────────────────────────────────────────────────────────────────
create table if not exists profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  username     text unique,
  currency     text not null default 'USD',
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

-- ── Row-Level Security ────────────────────────────────────────────────────────
alter table profiles     enable row level security;
alter table transactions enable row level security;
alter table friendships  enable row level security;
alter table debts        enable row level security;
alter table inbox_items  enable row level security;

-- profiles: anyone authenticated can read (needed for user search)
create policy "profiles_read_all"
  on profiles for select
  using (auth.role() = 'authenticated');

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
