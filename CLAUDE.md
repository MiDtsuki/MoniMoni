# CLAUDE.md

## Project
Moni is a Flutter finance app for mobile and web.
Offline-first: local Drift (SQLite) is the source of truth for the UI. A background sync engine reconciles with Supabase.

## Tech Stack
| Layer | Package |
|---|---|
| State management | `flutter_riverpod` |
| Navigation | `go_router` |
| Charts | `fl_chart` |
| Formatting | `intl` |
| ID generation | `uuid` |
| Icons | `lucide_icons_flutter` |
| Immutable models | `freezed` + `freezed_annotation` |
| Local DB | `drift` + `sqlite3_flutter_libs` |
| Remote backend | `supabase_flutter` |
| Code generation | `build_runner`, `drift_dev` |

## Architecture
Five layers. Dependency direction: Presentation → Application → Domain ← Data ← Backend.
Domain never imports Flutter or any external package.

```
lib/
  domain/
    models/          # freezed entities: Transaction, Debt, AppUser, Inbox
    repositories/    # abstract repository interfaces (pure Dart)
    usecases/        # business rules (optional, use when logic is non-trivial)

  application/
    transaction/     # TransactionCtrl (AsyncNotifier)
    debt/            # DebtCtrl (AsyncNotifier)
    stats/           # StatsCtrl (AsyncNotifier)
    friends/         # FriendsCtrl (AsyncNotifier)
    inbox/           # InboxCtrl (AsyncNotifier)

  data/
    local/
      drift_db.dart  # AppDatabase (@DriftDatabase), all DAOs
      daos/          # TransactionDao, DebtDao, UserDao, InboxDao
      tables/        # Drift table definitions
    remote/
      supabase_client.dart   # singleton SupabaseClient provider
      transaction_remote.dart
      debt_remote.dart
      user_remote.dart
    repositories/    # concrete implementations: coordinate Local + Remote
    sync/
      sync_engine.dart  # background reconciliation: Drift ↔ Supabase

  presentation/
    router.dart      # GoRouter definition
    screens/
      transactions/  # TransactionListScreen, AddTransactionScreen
      debts/         # DebtListScreen, BorrowScreen, LendScreen, SettleScreen
      stats/         # StatsScreen (pie chart, totals)
      profile/       # ProfileScreen (user info, currency)
      inbox/         # InboxScreen (friend/debt/settlement requests)
    widgets/         # shared reusable widgets

  main.dart          # ProviderScope + SupabaseInit + runApp only
```

## Postgres Schema (Supabase)
```sql
-- users managed by Supabase Auth; extend with:
create table profiles (
  id          uuid primary key references auth.users(id),
  display_name text not null,
  currency    text not null default 'THB',
  created_at  timestamptz default now()
);

create table transactions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references profiles(id),
  type        text not null check (type in ('income','expense')),
  category    text not null,
  amount      numeric(12,2) not null,
  note        text,
  date        date not null,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now(),
  deleted_at  timestamptz          -- soft delete for sync
);

create table debts (
  id           uuid primary key default gen_random_uuid(),
  owner_id     uuid not null references profiles(id),
  counterpart_id uuid not null references profiles(id),
  direction    text not null check (direction in ('borrow','lend')),
  amount       numeric(12,2) not null,
  description  text,
  status       text not null default 'pending' check (status in ('pending','settled')),
  created_at   timestamptz default now(),
  updated_at   timestamptz default now(),
  deleted_at   timestamptz
);

create table inbox_items (
  id           uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references profiles(id),
  sender_id    uuid not null references profiles(id),
  type         text not null check (type in ('friend_request','debt_request','settlement_request')),
  payload      jsonb,
  status       text not null default 'pending' check (status in ('pending','accepted','rejected')),
  created_at   timestamptz default now()
);

-- Enable RLS on all tables. Each user sees only their own rows.
alter table profiles      enable row level security;
alter table transactions  enable row level security;
alter table debts         enable row level security;
alter table inbox_items   enable row level security;
```

## Offline-First Sync Rules
- **Read path:** UI always reads from Drift. Never query Supabase directly from a screen or notifier.
- **Write path:** Write to Drift first (optimistic), mark row `synced = false`, return immediately. Sync engine pushes to Supabase in background.
- **Sync engine:** On connectivity restore, `SyncEngine` upserts all `synced = false` rows to Supabase and pulls remote changes since `last_synced_at`.
- **Soft deletes:** Use `deleted_at` timestamp. Never hard-delete locally until sync confirms remote deletion.
- **Conflicts:** Last-write-wins on `updated_at`. Remote wins on conflict for shared rows (debts, inbox).
- **Realtime:** Subscribe to Supabase Realtime for `debts` and `inbox_items` tables to push live updates into Drift.

## Coding Rules
- All state lives in Riverpod `AsyncNotifier` — no `setState`, no `ValueNotifier`, no singletons.
- `main.dart` only: `SupabaseInit`, `ProviderScope`, `runApp`. Nothing else.
- All domain models use `freezed` — `copyWith`, `==`, `hashCode` generated, fields immutable.
- All DAOs return domain models, not Drift `DataClass` rows — map at the DAO boundary.
- Repository interfaces live in `domain/repositories/`. Implementations live in `data/repositories/`.
- Notifiers depend on repository interfaces, not concrete implementations (inject via Riverpod).
- Amount fields: numeric keyboard, validate numbers only, reject non-numeric input.
- Date fields: default to `DateTime.now()`, use a date picker widget.
- Forms: validate before submit, show inline error messages.
- Use `uuid` for all entity IDs generated client-side. Supabase `gen_random_uuid()` for server rows.
- Use `intl` for all currency and date formatting.
- Never use `dynamic`. Be explicit with types everywhere.

## Design Rules
- Primary color: soft green — `Color(0xFF4CAF7D)` or equivalent.
- Background: white or light grey — no dark mode unless asked.
- Cards: `BorderRadius.circular(16)`, subtle box shadow.
- Typography: minimal — only show text that earns its place.
- Icons: `lucide_icons_flutter` only. Fall back to Material Icons only if lucide lacks the icon.
- Layout: mobile-first. Use `LayoutBuilder` or `MediaQuery` for responsive breakpoints.
- No hardcoded pixel widths for content — use flex, constraints, or percentages.
- Padding: multiples of 8px throughout.

## Features in Scope
1. Income and expense logging (add, edit, soft-delete transactions)
2. Debt tracking — borrow, lend, settle between friends
3. Statistics screen — pie chart by category, income vs expense totals
4. Profile dashboard — display name, currency preference
5. Inbox — friend requests, debt requests, settlement requests

## What NOT to Do
- Do not add features outside the scope list above unless asked.
- Do not query Supabase from screens or notifiers — go through the repository.
- Do not bypass the offline-first rule even for "simple" reads.
- Do not hardcode UI in `main.dart`.
- Do not refactor working code while fixing a bug — fix only what is broken.
- Do not add comments that just describe what the code does.
- Do not leave TODO comments in finished code.
- Do not hard-delete rows — always soft-delete via `deleted_at`.

## File Naming
- Screens: `*_screen.dart`
- Widgets: descriptive name or `*_widget.dart`
- Notifiers: `*_notifier.dart`
- Providers: `*_provider.dart`
- DAOs: `*_dao.dart`
- Drift tables: `*_table.dart`
- Repository interfaces: `*_repository.dart` (in domain)
- Repository implementations: `*_repository_impl.dart` (in data)
- Models: singular noun — `transaction.dart`, `debt.dart`, `app_user.dart`

## Code Generation
Run after any change to freezed models, drift tables, or DAOs:
```
flutter pub run build_runner build --delete-conflicting-outputs
```
Generated files (`*.freezed.dart`, `*.g.dart`) are committed to the repo.
