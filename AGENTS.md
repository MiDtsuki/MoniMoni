# AGENTS.md

## Project
Moni is a Flutter finance app for mobile and web.

The intended product direction is offline-first:
- Drift/SQLite should become the UI source of truth.
- A background sync layer should reconcile local changes with Supabase.

## Current Repo Reality
This repository is not at the intended offline-first architecture yet.

What exists now:
- Flutter UI for auth, transactions, debts, stats, profile, and inbox
- Riverpod state built mostly with `StateNotifier` and simple `Provider`s
- Supabase auth and table access wired directly into controllers and some UI
- A minimal Drift database shell with no tables/DAOs powering app features yet
- Supabase SQL schema checked into `supabase/schema.sql`

What is not done yet:
- Drift-backed repositories for app features
- Offline-first read/write flow
- Sync engine and conflict handling
- Realtime-to-Drift reconciliation
- Full clean architecture separation
- Migration to `AsyncNotifier`
- Freezed domain models across the app

Agents working here should preserve momentum toward the target architecture without pretending the migration is already complete.

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

`Presentation -> Application -> Domain <- Data <- Backend`

Rules:
- Domain should remain pure Dart.
- Presentation should not talk to Supabase directly.
- Application should depend on repository abstractions, not transport details.
- Data should own local/remote coordination.

Target structure:

```text
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

Current code does not fully match this structure. When making changes:
- prefer moving new work toward this layout
- avoid large opportunistic rewrites unless explicitly requested
- keep working features stable while migrating incrementally

## Offline-First Rules
These are the target rules for future work:
- UI reads should come from Drift, not Supabase.
- Writes should go local first, then sync outward.
- Use `deleted_at` for soft deletes.
- Sync should use `updated_at` and `last_synced_at` style reconciliation.
- Shared-row conflicts should be resolved deterministically.
- Realtime should feed local state, not bypass it.

Until that migration exists:
- do not add more direct Supabase access in screens
- avoid expanding controller-level table access if a repository boundary can be introduced instead
- treat existing direct Supabase calls as transition-state code, not the desired end state

## Database And Backend
Supabase is in scope for this repo.

Current backend-related assets:
- auth via `supabase_flutter`
- tables and RLS policies in `supabase/schema.sql`
- transaction/debt/friend/inbox/profile flows wired against Supabase tables

Drift is also in scope, but currently underused.

When working on persistence:
- prefer implementing real Drift tables/DAOs instead of adding more placeholder files
- keep local schema and Supabase schema conceptually aligned
- never hard-delete feature rows when soft delete is expected

## State Management
Current state is mostly Riverpod `StateNotifier`.
Target state is Riverpod `AsyncNotifier` where async loading and persistence matter.

Instructions:
- do not introduce `setState` for app-level data flow
- local widget interaction state is acceptable temporarily, but business state belongs in Riverpod
- prefer repository-backed notifiers over table-access code inside UI
- migrate toward `AsyncNotifier` for feature controllers when touching that area substantially

## Models
Target rule:
- domain models should use `freezed`

Current reality:
- most current models are hand-written immutable classes

Instructions:
- do not mix `dynamic` into model boundaries
- prefer explicit typed mapping
- if you introduce or heavily revise a domain model, bias toward `freezed`

## UI And Design
Design direction:
- soft green primary color
- white/light background
- rounded cards
- minimal copy
- mobile-first responsive layout
- `lucide_icons_flutter` first

UI rules:
- no hardcoded UI in `main.dart`
- keep reusable widgets reusable
- validate forms properly
- amount inputs must remain numeric-only
- date fields should default to current system date/time
- use responsive constraints instead of rigid page widths where possible

## Features In Scope
1. Income and expense logging
2. Debt tracking between friends
3. Statistics with charts
4. Profile dashboard
5. Inbox for friend, debt, and settlement requests

## What Not To Do
- Do not claim the app is frontend-only.
- Do not remove Supabase usage unless explicitly asked.
- Do not add Firebase or another backend.
- Do not bypass Riverpod for feature state.
- Do not query Supabase directly from new screens if a provider/repository boundary is available.
- Do not hard-delete rows that should use `deleted_at`.
- Do not refactor broad unrelated areas while fixing a localized bug.
- Do not leave placeholder architecture claims that are false for the current repo.

## File Naming
Preferred naming moving forward:
- Screens: `*_screen.dart`
- Widgets: descriptive name or `*_widget.dart`
- Notifiers: `*_notifier.dart`
- Providers: `*_provider.dart`
- DAOs: `*_dao.dart`
- Drift tables: `*_table.dart`
- Repository interfaces: `*_repository.dart`
- Repository implementations: `*_repository_impl.dart`
- Models: singular noun such as `transaction.dart`, `debt.dart`, `app_user.dart`

Existing files do not all follow this yet. Do not rename broad swaths of files unless requested.

## Code Generation
Run after changing Drift tables, DAOs, or Freezed models:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Generated files such as `*.g.dart` and `*.freezed.dart` should be committed when they are part of the change.

## Review Priorities
When reviewing or modifying this repo, prioritize:
- runtime breakage over style
- architecture regressions over superficial cleanup
- test failures over analyzer cleanliness
- places where current code contradicts the intended offline-first direction
- silent error swallowing and brittle state assumptions
