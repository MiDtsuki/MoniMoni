# Firebase Completion Plan

This file tracks the remaining Firebase-first work for Moni.

## Current Status

Completed in code:
- Firebase packages added
- Firebase initialization scaffolded
- Auth migrated to Firebase Auth
- Profile, transactions, friends, debts, and inbox flows migrated to Firestore
- Old backend runtime code removed
- Tests updated and passing

Still required before final deployment:
- replace placeholder `lib/firebase_options.dart` with generated FlutterFire config
- configure platform Firebase files through `flutterfire configure`
- add Firestore Security Rules
- deploy Cloud Functions for score-sensitive writes
- verify Firestore indexes prompted by real queries

## Manual Tasks For You

1. Run FlutterFire config in this repo:

```bash
flutterfire configure
```

2. Confirm Firebase Auth Email/Password is enabled.

3. Confirm Firestore is enabled.

4. Deploy Firestore rules after we finalize them:

```bash
firebase deploy --only firestore:rules
```

5. Initialize and deploy Cloud Functions when the score logic is moved server-side:

```bash
cd functions
npm install
firebase deploy --only functions
```

## Remaining Implementation Phases

1. Deploy Firestore rules that protect user data and prevent direct score tampering.
2. Deploy overdue-penalty and settlement scoring Cloud Functions.
3. Swap the placeholder Firebase options file for generated config.
4. Run end-to-end testing on signup, login, transactions, friends, debts, inbox, and score updates.

## Validation Checklist

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- sign up
- log in
- reset password email
- add transaction
- add friend request
- accept friend request
- create debt request
- accept debt request
- settle debt
- verify score changes
