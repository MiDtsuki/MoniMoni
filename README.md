# Moni

Moni is a Flutter finance app for mobile and web with these feature areas:
- transactions
- debts between friends
- stats
- profile
- inbox and request flows

## Current Status

The intended architecture is offline-first with Drift as the local source of truth and Supabase sync in the background.

The current app is not there yet.

What works today:
- Flutter UI is implemented
- Supabase auth is wired
- Supabase tables are used for transactions, debts, profiles, friendships, and inbox items
- Basic Drift scaffolding exists in the repo

What is still in progress:
- Drift-backed feature storage
- repository-based local/remote coordination
- sync engine
- full offline-first behavior

For now, developers should treat this app as a Flutter client that must have a working Supabase backend to function.

## Prerequisites

- Flutter SDK matching the repo Dart constraint in `pubspec.yaml`
- A device, emulator, browser, or desktop target supported by Flutter
- Access to a Supabase project

Verify Flutter locally:

```bash
flutter doctor
```

## Install Dependencies

```bash
flutter pub get
```

## Supabase Setup

The app currently initializes Supabase directly in `lib/main.dart`.

Two ways to work:

1. Use the currently configured Supabase project already checked into `lib/main.dart`
2. Point the app at your own Supabase project and update the values in `lib/main.dart`

If you use your own project:

1. Create a Supabase project.
2. Open the SQL editor.
3. Run the schema from `supabase/schema.sql`.
4. Copy your project URL and anon key into `lib/main.dart`.

Notes:
- The app expects email/password auth through Supabase Auth.
- The schema creates profiles, transactions, friendships, debts, and inbox tables.
- The schema also enables RLS policies needed by the current client-side flows.

## Run The App

Mobile or desktop:

```bash
flutter run
```

Web:

```bash
flutter run -d chrome
```

## First-Time Developer Flow

If you want another developer to get productive quickly, this is the fastest path:

1. Clone the repo.
2. Run `flutter pub get`.
3. Confirm the Supabase URL and anon key in `lib/main.dart` point to a usable project.
4. If using a fresh Supabase project, run `supabase/schema.sql`.
5. Start the app with `flutter run`.
6. Create a test account through the signup screen.
7. Log in and verify these flows:
   - add a transaction
   - add a friend request
   - create a debt request
   - open stats
   - open profile and inbox

## Current Architecture Notes

The repo contains `domain`, `application`, `data`, and `presentation` directories, but the migration is incomplete.

Important current behavior:
- feature controllers still talk to Supabase directly
- screens still depend on Riverpod state that is backed by Supabase calls
- Drift is not yet the runtime source of truth for app features

When developing, prefer moving new work toward:
- repository boundaries
- typed domain models
- local-first persistence
- reduced direct Supabase access from UI-facing code

## Code Generation

Run this after changing Drift definitions or Freezed models:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Generated files should be committed when they are part of the change.

## Validation Commands

Static analysis:

```bash
flutter analyze
```

Tests:

```bash
flutter test
```

## Known Development Caveats

- `flutter analyze` is currently clean.
- `flutter test` is currently not clean because app startup assumes `Supabase.instance` is initialized before router creation.
- Transaction date entry currently captures time in the UI, but transaction serialization stores date-only.
- The offline-first Drift architecture described in planning docs is not fully implemented yet.

## Scope

Main scope:
- income and expense logging
- debt tracking
- statistics
- profile dashboard
- inbox flows

Out of scope unless explicitly requested:
- Firebase
- replacing Supabase with another backend
- broad unrelated refactors
