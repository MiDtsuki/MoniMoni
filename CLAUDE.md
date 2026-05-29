# Moni Workspace Notes

Moni (a.k.a. MoniOmega) is a Flutter app for tracking personal transactions and peer-to-peer debts with a demo credit-scoring system. This is a school project: prioritize demo-able behavior over production hardening.

## Stack

- Flutter (Dart 3.10.7), Material 3
- State: `flutter_riverpod` 2.x using `StateNotifierProvider` + immutable state classes with hand-written `copyWith`. Freezed is in `pubspec.yaml` but unused — models are hand-written `fromMap`/`toMap`.
- Routing: `go_router` 14.x with a `StatefulShellRoute.indexedStack` (4 tabs: Logs, Debts, Stats, Profile) and an auth-state redirect guard.
- Backend: Firebase only — Auth, Cloud Firestore, and (written but not deployed) Cloud Functions.
- Local: Drift + sqlite3 are wired but currently inert (no tables, no DAOs). Guest mode uses `SharedPreferences` via `lib/data/local/guest_store.dart`, not Drift.
- Platforms configured: Android, iOS, Web have real Firebase config in `lib/firebase_options.dart` and are the supported targets. Windows / macOS / Linux entries are still placeholders.

## Directory layout

- `lib/main.dart` — Firebase init, dotenv load, guest-session bootstrap, then `runApp(MoniApp)`.
- `lib/app/` — `app.dart` (root `MaterialApp.router`), `router.dart` (GoRouter + bottom-nav shell), `theme.dart`.
- `lib/core/`
  - `firebase/user_records.dart` — account-record helpers; see "User identity model" below.
  - `providers/firebase_providers.dart` — `FirebaseAuth`, `FirebaseFirestore`, and `authStateChanges` providers.
  - `providers/session_providers.dart` — guest-mode `ChangeNotifier`.
  - `constants/`, `utils/currency_formatter.dart`, `widgets/` (shared UI: `MoniCard`, `EmptyState`, `SectionHeader`, `AppPage`).
- `lib/features/` — feature-first slices, each with `application/` (controllers), `domain/` (models), `presentation/` (pages):
  - `auth/` — `login_page`, `signup_page`.
  - `debts/` — `debt_controller`, `friends_controller`, `guest_debt_note_controller`; pages for list/detail/form.
  - `transactions/` — `transaction_controller` + list/form pages. Lives under `users/{uid}/transactions`.
  - `profile/` — `profile_settings_controller`, `notification_controller`, profile + inbox pages.
  - `stats/` — `stats_page` (fl_chart-based).
  - `credit_score/domain/credit_score_calculator.dart` — pure score math; **the only feature with real tests**.
- `lib/data/local/` — Drift scaffolding + `guest_store.dart` + a manual `db_test_page` for debugging.
- `functions/` — TypeScript Cloud Functions (see "Cloud Functions" below).
- `firestore.rules` — active security rules (deployed).
- `test/credit_score_calculator_test.dart` — only meaningful test.

## Firestore collections

All top-level unless noted.

- `users/{uid}` — private account data: `email`, `full_name`, `currency`, `credit_score`, `created_at`. Self-only read/write.
- `users/{uid}/transactions/{txId}` — personal income/expense ledger (subcollection).
- `user_profiles/{uid}` — public/searchable profile: `username`, `username_lower`, `display_name`, `display_name_lower`, `created_at`. Signed-in readable; owner-only writes.
- `username_claims/{username_lower}` — uniqueness lock: `owner_uid`, `username_lower`, `created_at`. Create-only.
- `friendships/{friendshipId}` — `participants: [uidA, uidB]`, `created_at`. Participant-scoped.
- `debts/{debtId}` — `owner_id`, `counterpart_id`, `participants`, `direction` (`lend`|`borrow`), `amount`, `description`, `status` (`pending`→`active`→`settled`), `deadline`, `created_at`, `updated_at`, `settled_at`. Participant-scoped.
- `inbox_items/{itemId}` — request envelopes: `recipient_id`, `sender_id`, `type` (`friend_request`, `friend_request_accepted`, `debt_request`, `debt_accepted`, `debt_declined`, `settlement_request`), `payload`, `status`, `created_at`. Sender + recipient can read; only recipient can update status.
- `credit_score_events/{eventId}` — append-only score deltas: `user_id` (borrower), `debt_id`, `event_type` (`missed_deadline` | `overdue_day` | `on_time_settlement`), `points`, `event_date`, `created_at`. Readable by event owner or any participant of the referenced debt.

`credit_score_events` is the source of truth for the displayed score — the `credit_score` field on `users/{uid}` is treated as a cached/legacy value. `profile_settings_controller` recomputes the score by summing events and feeding them into `CreditScoreCalculator`.

## User identity model

`username` is the public app identity (used everywhere the user is shown and for search). `full_name` is private and only persisted in `users/{uid}`. There is no separate "display name" concept anymore — the `display_name` / `display_name_lower` fields on `user_profiles` exist for schema compatibility and are kept in sync with `username` by `user_records.dart`.

Username rules: 3–20 chars, lowercase letters/numbers/underscores (`^[a-z0-9_]{3,20}$`). Enforced both client-side (`isValidUsername`) and in Firestore rules.

Account creation goes through `createAccountRecords()` (signup) or `ensureAccountRecords()` (idempotent repair on login if any of the three docs are missing). Both run a single Firestore transaction that touches `users`, `user_profiles`, and `username_claims` together — never write to any of them directly elsewhere.

## Cloud Functions

`functions/src/index.ts` contains two functions:

- `backfillOverdueCreditScores` — daily scheduled scan that emits `overdue_day` / `missed_deadline` events.
- `handleDebtSettlementCreditScore` — Firestore trigger that awards `on_time_settlement` on debt settle.

**These are not deployed.** The project is on the Firebase Spark plan; Functions requires Blaze. For now, equivalent logic runs client-side in `debt_controller._applyCreditScoreEvent` and during settlement acceptance. Rules were intentionally relaxed to allow debt participants to create `credit_score_events` for the borrower of a referenced debt — read [firestore.rules](firestore.rules) before changing this.

Keep the Functions code working as a reference for the eventual server-side migration, but do not assume it runs.

## Search

Friend/user search is prefix-based on `user_profiles.username_lower` using `where('username_lower', isGreaterThanOrEqualTo: q).where('username_lower', isLessThanOrEqualTo: '$q')` (or `orderBy` + `startAt`/`endAt` equivalent). Do not introduce a search service — keep it pure Firestore.

## Inbox / request flow

Every cross-user action (friend request, debt request, settlement request, plus accepted/declined notifications) is an `inbox_items` doc. The recipient mutates `status`; the sender sees their outgoing items as `Pending` in the inbox UI. `friends_controller` and `debt_controller` each subscribe to both incoming and outgoing inbox streams so the sender's UI reflects pending state without a separate "outbox" collection.

## Guest mode

`guestSessionProvider` flips the auth-redirect guard. Guest data lives in `SharedPreferences` (`guest_store.dart`) — no Firestore, no Auth. Keep this path working when changing controllers: most of them have a guest branch that must not call Firebase.

## Constraints

- Pure Firebase — do not add another backend.
- Username search stays prefix-based on `username_lower`.
- Guest mode stays offline-capable.
- Demo-safe over production-hardened: client-side credit-score writes are acceptable while on Spark.
- Don't write to `users` / `user_profiles` / `username_claims` outside `user_records.dart`.

## Web build & deploy

The same Flutter codebase runs on the web. Firebase Hosting is wired in `firebase.json` and `.firebaserc` points at the `moni-624c6` project.

- Local dev: `flutter run -d chrome`
- Release build: `flutter build web --release --no-tree-shake-icons` (the `--no-tree-shake-icons` flag is required — `lucide_icons_flutter` uses non-const `IconData`, which trips Flutter's tree-shaker).
- Deploy: `firebase deploy --only hosting` (deploys `build/web/` to `https://moni-624c6.web.app`).
- `https://moni-624c6.web.app` and `https://moni-624c6.firebaseapp.com` are automatically authorized for Firebase Auth. If you deploy under a custom domain, add it under Authentication → Settings → Authorized domains.

Known web limitations (build succeeds, but feature degrades at runtime):

- Bank-slip QR verification (`SlipVerificationService.readQrPayload`) goes through `mobile_scanner`. On web, `image_picker` returns an `XFile` whose `path` is a blob URL, which `MobileScannerController.analyzeImage` cannot decode — the verify-receipt flow will throw. Use cash settlement on web, or fall back to the mobile app.
- Drift uses `connection_web.dart` (the legacy `package:drift/web.dart` IndexedDB backend) — fine for now because there are no tables, but if Drift is ever adopted, migrate to `drift_flutter` + `sqlite3.wasm`.

## Known gaps / follow-up

- `lib/firebase_options.dart` is incomplete for Windows / macOS / Linux — run `flutterfire configure` if you need those platforms.
- Functions are written but undeployed (needs Blaze).
- `lib/data/repositories/` and `lib/data/sync/` are empty placeholders.
- Drift is wired but has zero tables — either adopt it or remove it.
- Freezed is a dependency but no model uses it; models are hand-written.
- Tests cover only the credit-score calculator.
