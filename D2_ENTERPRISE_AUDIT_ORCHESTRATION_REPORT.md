# D2 Enterprise Audit & Orchestration Report

This document is a delivery-aligned draft for the MoniOmega enterprise audit
and orchestration report. It captures the current repository evidence, the
architecture and security decisions already implemented, and the remaining gaps
that should be stated clearly in the final submission.

## 1. Report Scope

This report covers the four required D2 areas:

- Agent workflow and multi-agent orchestration
- Architecture and data design
- Security matrix and Firestore Security Rules
- Observability and rollback readiness

The repository already provides strong evidence for the first three areas. The
main remaining implementation gap is feature-flag rollback. Crash reporting is
now wired through a cross-platform abstraction with real Firebase Crashlytics
on supported native platforms and a web-safe fallback logger for Flutter web.

## 2. Evidence Inventory

The following repository artifacts support this report:

- `CLAUDE.md`: project memory, stack, architecture, constraints, conventions
- `AGENTS.md`: concise repo-level operational rules
- `.claude/agents/README.md`: prompt-definition folder index
- `.claude/agents/flutter-maintainer.md`: Flutter and CI-safe prompt
- `.claude/agents/firestore-guardian.md`: Firebase schema and rules prompt
- `.github/workflows/flutter-ci.yml`: CI workflow for formatting, analysis, and
  tests
- `firestore.rules`: active Firestore Security Rules
- `lib/core/firebase/user_records.dart`: centralized identity and username
  record management
- `lib/core/providers/firebase_providers.dart`: Firebase provider entry points
- `lib/core/providers/session_providers.dart`: guest-session orchestration
- `lib/data/local/guest_store.dart`: local-only guest persistence
- `lib/features/**/application/*_controller.dart`: Riverpod state management
- `functions/src/index.ts`: reference Cloud Functions for future hardening

## 3. Agent Workflow

### 3.1 Multi-Agent Orchestration Model

The project uses a layered prompt and memory structure rather than a single
flat instruction file.

- `CLAUDE.md` acts as long-form project memory. It stores stack choices,
  collection schema, architectural constraints, guest-mode rules, deployment
  notes, and known gaps.
- `AGENTS.md` acts as a concise repo rules file. It emphasizes the current
  backend choice, active Firestore collections, search behavior, credit-score
  constraints, and Firebase-specific development notes.
- `.claude/agents/` acts as the prompt-definition folder required by the
  deliverable. Each file represents a focused working role:
  - `flutter-maintainer.md` constrains Flutter changes to remain CI-safe and
    architecture-consistent.
  - `firestore-guardian.md` constrains data-layer work to preserve Firestore
    schema and guest-mode assumptions.

This structure supports practical multi-agent orchestration because each
specialized prompt can be invoked for a narrower task without losing the shared
project memory encoded in `CLAUDE.md` and `AGENTS.md`.

### 3.2 Prompts Used

The prompt surfaces used by the team are represented by repository files:

- `CLAUDE.md`
- `AGENTS.md`
- `.claude/agents/flutter-maintainer.md`
- `.claude/agents/firestore-guardian.md`

These files serve as reusable prompt inputs for task execution, review, and
handoff. They reduce repeated explanation overhead and help preserve critical
constraints across sessions.

### 3.3 Context Drift Challenges

The main context-drift risks in this project are:

- Backend drift: accidentally reintroducing a non-Firebase backend even though
  Firebase is the active backend
- Schema drift: changing Firestore field names inconsistently across models,
  controllers, and rules
- Identity drift: writing to `users`, `user_profiles`, or `username_claims`
  outside the centralized account-record path
- Search drift: replacing the prefix-based `username_lower` strategy with an
  incompatible search pattern
- Guest-mode drift: introducing Firebase calls into offline guest flows
- Credit-score drift: mixing current app-side score mutations with a partially
  assumed server-side model

### 3.4 Handoff Management

Handoffs are managed through explicit artifact layering:

- Long-lived architectural and schema knowledge lives in `CLAUDE.md`
- Short operational constraints live in `AGENTS.md`
- Task-focused roles live in `.claude/agents/`
- Automated verification lives in `.github/workflows/flutter-ci.yml`

This means a handoff does not rely only on chat memory. The next contributor or
agent can reconstruct the intended operating model from repository artifacts and
then validate changes through CI.

### 3.5 Mitigations for Context Drift

The current project mitigates drift using:

- Explicit top-level memory files (`CLAUDE.md`, `AGENTS.md`)
- Specialized prompt-definition files in `.claude/agents/`
- Centralized identity-write logic in `lib/core/firebase/user_records.dart`
- Firestore rule enforcement in `firestore.rules`
- CI checks for formatting, `flutter analyze`, and `flutter test`

This is a pragmatic orchestration model for a student project because it keeps
the coordination overhead low while still making architectural rules explicit
and testable.

## 4. Architecture & Data

### 4.1 System Overview

MoniOmega is a Flutter application for personal transaction tracking,
peer-to-peer debts, inbox-driven social workflows, and a demo credit-scoring
system.

Core stack:

- Flutter with Material 3
- `flutter_riverpod` for application state
- `go_router` for navigation
- Firebase Auth for authentication
- Cloud Firestore for remote data
- SharedPreferences for local-only guest mode
- Drift scaffolding present locally but not active as the main backend

### 4.2 Domain Modeling

The current domain is organized around these core concepts:

- User account: private account data in `users/{uid}`
- Public identity profile: searchable public identity in `user_profiles/{uid}`
- Username uniqueness claim: lock record in `username_claims/{username_lower}`
- Transaction ledger: per-user financial logs in `users/{uid}/transactions`
- Friendship relation: canonical relationship docs in `friendships`
- Debt relation: shared debt lifecycle in `debts`
- Inbox workflow: request and notification envelopes in `inbox_items`
- Credit-score event log: append-only scoring events in `credit_score_events`

This split separates private account state, public profile state, transactional
state, social graph state, workflow state, and score-event state.

### 4.3 Firestore Collection and Sub-Collection Hierarchy

Top-level collections:

- `users`
- `user_profiles`
- `username_claims`
- `friendships`
- `debts`
- `inbox_items`
- `credit_score_events`

Nested sub-collection:

- `users/{uid}/transactions`

Hierarchy rationale:

- Transactions live under a user because they are private, user-scoped ledger
  entries rather than shared documents.
- Friendships and debts are top-level because they are cross-user entities with
  participant-based authorization rules.
- Inbox items are top-level because they model cross-user requests and
  notifications.
- Username claims are top-level because uniqueness needs a dedicated lock
  document.
- Credit-score events are top-level because they are append-only records linked
  to debts and borrowers across the domain.

### 4.4 State Management Justification

The project uses `flutter_riverpod` with `StateNotifierProvider` as the main
state-management approach.

Justification:

- Feature controllers are isolated by domain under
  `lib/features/<feature>/application`
- `StateNotifierProvider` gives predictable mutable workflow boundaries while
  keeping exposed state immutable
- The pattern is sufficient for this app without introducing heavier enterprise
  layers such as Bloc, Redux, or a custom repository framework
- Shared Firebase objects are exposed through providers in
  `lib/core/providers/firebase_providers.dart`
- Guest-mode session state uses a `ChangeNotifier` in
  `lib/core/providers/session_providers.dart` because it must bridge persisted
  local session state with router redirects

This is a defensible choice because the app has multiple feature slices, but it
is still small enough that `StateNotifierProvider` remains simple, readable, and
maintainable.

## 5. Security Matrix

### 5.1 RBAC-Oriented Access Matrix

The Firestore rules are not role names in the traditional IAM sense, but they
map cleanly to application roles and relationship scopes.

| Role / Scope | Collection | Read | Create | Update | Delete | Rule Basis |
| --- | --- | --- | --- | --- | --- | --- |
| Guest user | All Firestore collections | No | No | No | No | `request.auth == null` is rejected throughout |
| Authenticated self | `users/{uid}` | Yes, self only | Yes, self only | Yes, limited fields | No | `isSelf(userId)` + validation helpers |
| Authenticated self | `users/{uid}/transactions/{txId}` | Yes, self only | Yes, self only | Yes, self only | Yes, self only | `isSelf(userId)` |
| Signed-in user | `user_profiles/{uid}` | Yes | Own profile only | Own profile, limited fields | No | `signedIn()`, `isSelf(userId)` |
| Signed-in user | `username_claims/{username}` | Yes | Own claim only | No | No | username validation + owner match |
| Friendship participant | `friendships/{friendshipId}` | Yes | Yes, with canonical id and accepted inbox proof | Locked/no-op only | Yes | participant membership + `inboxBacksFriendship()` |
| Debt participant | `debts/{debtId}` | Yes | Authenticated owner creates | Participants can update limited lifecycle fields | Yes | participant membership + debt validators |
| Inbox sender or recipient | `inbox_items/{itemId}` | Yes | Sender creates with valid shape | Recipient updates status only | No | `isInboxParty()` + inbox validators |
| Debt participant / event owner | `credit_score_events/{eventId}` | Yes | Yes, limited event types and referenced debt validation | No | No | debt lookup + borrower resolution |

### 5.2 Firestore Security Rules Explanation

The rules implement several important control patterns:

- Authentication gate:
  - `signedIn()` blocks unauthenticated Firestore access
- Self-scope access:
  - `isSelf(userId)` restricts private account and nested transaction data to
    the authenticated owner
- Relationship-scope access:
  - participant checks protect `friendships` and `debts`
  - inbox-party checks protect `inbox_items`
- Strict schema validation:
  - helper functions such as `validUserCreateData()`,
    `validDebtUpdateData()`, and `validInboxUpdateData()` constrain document
    fields and permissible updates
- Username integrity:
  - `validUsername()` standardizes allowed usernames
  - `ownsUsernameClaim()` ensures the profile create path is backed by a
    matching username-claim document
- Canonical friendship creation:
  - `isCanonicalFriendshipId()` enforces a stable document id from sorted user
    ids
  - `inboxBacksFriendship()` uses `getAfter()` to confirm that friendship
    creation is tied to an accepted friend request in the same batch
- Credit-score event control:
  - `validCreditScoreEventCreateData()` restricts event creation to supported
    event types and ensures the event references a valid debt and the correct
    borrower

This rule design is strong for a school-project scope because it does more than
simple signed-in checks. It constrains both document shape and cross-document
workflow consistency.

## 6. Observability & Rollback

### 6.1 Current State

Current implementation:

- `pubspec.yaml` adds `firebase_crashlytics`
- `android/settings.gradle.kts` registers the Crashlytics Gradle plugin
- `android/app/build.gradle.kts` applies the Crashlytics Gradle plugin
- `lib/core/observability/crash_reporter.dart` defines the shared reporting
  abstraction
- `lib/core/observability/crash_reporter_native.dart` sends supported native
  reports to Firebase Crashlytics
- `lib/core/observability/crash_reporter_web.dart` keeps web builds safe with a
  local logging fallback
- `lib/main.dart` routes Flutter framework errors, platform-dispatcher errors,
  and zone-level uncaught errors through the crash reporter

Current findings:

- No explicit feature-flag framework was found in the Flutter codebase
- No Firebase Remote Config integration was found
- No runtime kill-switch or staged rollout logic was found

Platform note:

- Based on the current official FlutterFire package support matrix, Firebase
  Crashlytics supports Android, iOS, and macOS, but not web. The web path in
  this project therefore uses a no-op/local logging fallback rather than real
  Crashlytics reporting.

### 6.2 Current Observability Signals

The repository now has these observability safeguards:

- CI checks in `.github/workflows/flutter-ci.yml`
- Crash reporting hooks in `lib/main.dart`
- Native Crashlytics reporting through `lib/core/observability/`
- Firestore rules for data-layer protection
- Cloud Functions source code as future hardening references
- Git history and branch-based rollback at the source-code level
- Firebase Hosting deployment flow documented in `CLAUDE.md`

These help with delivery quality, but they do not yet provide a true feature
flag rollback mechanism.

### 6.3 Current Rollback Position

The defensible current rollback plan is:

- Revert the Git commit that introduced the faulty change
- Re-run CI (`dart format`, `flutter analyze`, `flutter test`)
- Rebuild the Flutter web app
- Redeploy the last known-good Firebase Hosting release

This is still an operational rollback plan, not a remote feature-disable plan.

### 6.4 Recommended Next Implementation

To strengthen this section for the final submission:

- Add a simple feature flag for a high-risk feature
- Prefer Firebase Remote Config or a local config wrapper for toggles
- Document a rollback path that disables the flag without requiring a full app
  redeploy

## 7. Risks and Gaps

The main risks that should be acknowledged honestly in the final report are:

- Observability is not yet production-grade on web because Crashlytics is not
  supported there by the official FlutterFire package
- Rollback is currently operational and Git-based, not feature-flag-driven
- Credit-score mutation still occurs client-side for Spark-plan reasons
- Cloud Functions exist as reference code but are not deployed
- Drift scaffolding remains present even though Firebase is the active backend

These are acceptable if documented transparently as scope and platform tradeoffs
for the current project stage.

## 8. Recommended Final Report Writing Order

To turn this draft into the final 5-8 page deliverable, write it in this order:

1. Agent workflow
2. Architecture and data model
3. Security matrix and rules explanation
4. Observability and rollback
5. Risks, limitations, and future hardening

This order works because the first three sections are already strongly supported
by repository evidence, while the last section can clearly distinguish between
implemented controls and planned improvements.
