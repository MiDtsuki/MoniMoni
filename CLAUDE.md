# CLAUDE.md

## Project
Moni is a Flutter finance app for mobile and web.

The intended product direction is offline-first:
- Drift/SQLite should become the UI source of truth.
- A background sync layer should reconcile local changes with Supabase.

## Current Repo Reality
This repository is not at the intended offline-first architecture yet.

What exists now:
- Flutter UI for auth, transactions, debts, stats, profile, and inbox
- Riverpod state built with `StateNotifier` and simple `Provider`s
- Supabase auth and table access wired directly into controllers
- Auth guard in the router — unauthenticated users are redirected to login
- Real signup and login via Supabase Auth with a `handle_new_user` trigger
- Full Supabase schema checked into `supabase/schema.sql`
- A minimal Drift database shell with no tables or DAOs powering app features yet
- `lib/core/providers/supabase_providers.dart` providing the client and current user

What is not done yet:
- Drift-backed repositories for any app feature
- Offline-first read/write flow
- Sync engine and conflict handling
- Realtime-to-Drift reconciliation
- Full clean architecture separation
- Migration to `AsyncNotifier`
- Freezed domain models across the app

Agents working here should preserve momentum toward the target architecture without pretending the migration is complete.

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
Target dependency direction:

`Presentation → Application → Domain ← Data ← Backend`

Rules:
- Domain should remain pure Dart.
- Presentation should not talk to Supabase directly.
- Application should depend on repository abstractions, not transport details.
- Data should own local/remote coordination.

Target structure:

```
lib/
  domain/
    models/
    repositories/
    usecases/

  application/
    transaction/
    debt/
    stats/
    friends/
    inbox/

  data/
    local/
      drift_db.dart
      daos/
      tables/
    remote/
      supabase_client.dart
      transaction_remote.dart
      debt_remote.dart
      user_remote.dart
    repositories/
    sync/
      sync_engine.dart

  presentation/
    router.dart
    screens/
      transactions/
      debts/
      stats/
      profile/
      inbox/
    widgets/

  main.dart
```

Current code does not fully match this structure. Controllers talk to Supabase directly — there are no repository interfaces or DAOs yet. When making changes:
- prefer moving new work toward this layout
- avoid large opportunistic rewrites unless explicitly requested
- keep working features stable while migrating incrementally

## Database And Backend
Supabase is the active backend.

Current backend-related assets:
- Auth via `supabase_flutter` (signup, login, signout, auth guard in router)
- Full schema and RLS policies in `supabase/schema.sql` — this is the source of truth for the DB shape
- Transactions, debts, friends, inbox, and profile flows wired against Supabase tables via controllers

Tables in use:
- `profiles` — extended from `auth.users` via trigger, stores display_name, username, currency
- `transactions` — income/expense logs per user, with soft delete via `deleted_at`
- `friendships` — bidirectional friend relationships
- `debts` — lend/borrow records with direction from owner's perspective
- `inbox_items` — friend, debt, and settlement requests with payload jsonb

Drift is also in scope but currently only has a shell (`AppDatabase` with no tables).

When working on persistence:
- prefer implementing real Drift tables and DAOs instead of expanding direct Supabase access
- keep local schema and Supabase schema conceptually aligned
- never hard-delete feature rows when soft delete is expected

## State Management
Current state is Riverpod `StateNotifier`.
Target state is Riverpod `AsyncNotifier` where async loading and persistence matter.

Instructions:
- do not introduce `setState` for app-level data flow
- local widget interaction state is acceptable temporarily, but business state belongs in Riverpod
- prefer repository-backed notifiers over table-access code inside controllers
- migrate toward `AsyncNotifier` for feature controllers when touching that area substantially

## Models
Target rule: domain models should use `freezed`.

Current reality: all models are hand-written immutable classes with manual `copyWith`, `fromJson`, and `toJson`.

Instructions:
- do not mix `dynamic` into model boundaries
- prefer explicit typed mapping
- if you introduce or heavily revise a domain model, bias toward `freezed`

## Offline-First Rules
These are the target rules for future work:
- UI reads should come from Drift, not Supabase.
- Writes should go local first, then sync outward.
- Use `deleted_at` for soft deletes.
- Sync should use `updated_at` and `last_synced_at` style reconciliation.
- Shared-row conflicts should resolve deterministically.
- Realtime should feed local state, not bypass it.

Until that migration exists:
- do not add more direct Supabase access in screens
- avoid expanding controller-level table access if a repository boundary can be introduced instead
- treat existing direct Supabase calls as transition-state code, not the desired end state

## UI And Design
- Primary color: soft green — `Color(0xFF4CAF7D)`
- Background: white or light grey — no dark mode unless asked
- Cards: `BorderRadius.circular(16)`, subtle box shadow
- Typography: minimal — only show text that earns its place
- Icons: `lucide_icons_flutter` first, Material Icons only if lucide lacks the icon
- Layout: mobile-first, use `LayoutBuilder` or `MediaQuery` for responsive breakpoints
- Padding: multiples of 8px throughout
- No hardcoded pixel widths for content — use flex, constraints, or percentages

## Features In Scope
1. Income and expense logging (add, edit, soft-delete transactions)
2. Debt tracking — borrow, lend, settle between friends
3. Statistics screen — pie chart by category, income vs expense totals
4. Profile dashboard — display name, currency preference, sign out
5. Inbox — friend requests, debt requests, settlement requests

## What Not To Do
- Do not claim the app is offline-first — it is not yet.
- Do not add features outside the scope list above unless asked.
- Do not query Supabase directly from screens — go through a provider or controller.
- Do not hardcode UI in `main.dart`.
- Do not refactor working code while fixing a bug — fix only what is broken.
- Do not add comments that just describe what the code does.
- Do not hard-delete rows — always soft-delete via `deleted_at`.
- Do not add Firebase or another backend.
- Do not bypass Riverpod for feature state.

## File Naming
Preferred naming moving forward:
- Screens: `*_screen.dart`
- Widgets: descriptive name or `*_widget.dart`
- Notifiers: `*_notifier.dart`
- Providers: `*_provider.dart`
- DAOs: `*_dao.dart`
- Drift tables: `*_table.dart`
- Repository interfaces: `*_repository.dart` (in domain)
- Repository implementations: `*_repository_impl.dart` (in data)
- Models: singular noun — `transaction.dart`, `debt.dart`, `app_user.dart`

Existing files do not all follow this yet. Do not rename broad swaths of files unless requested.

## Code Generation
Run after any change to Drift tables, DAOs, or Freezed models:
```
flutter pub run build_runner build --delete-conflicting-outputs
```
Generated files (`*.freezed.dart`, `*.g.dart`) are committed to the repo.

## Review Priorities
When reviewing or modifying this repo, prioritize:
- runtime breakage over style
- architecture regressions over superficial cleanup
- places where current code contradicts the intended offline-first direction
- silent error swallowing and brittle state assumptions
- expanding direct Supabase access in places that should have a repository boundary
