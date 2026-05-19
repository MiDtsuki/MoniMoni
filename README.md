# Moni

Moni is a Flutter finance app with these feature areas:
- transactions
- debts between friends
- stats
- profile
- inbox and request flows

## Current Backend

The app is now Firebase-first:
- Firebase Auth for authentication
- Cloud Firestore for app data
- Drift scaffolding still exists locally, but Firebase is the active backend

## Prerequisites

- Flutter SDK matching the repo Dart constraint in `pubspec.yaml`
- A Firebase project
- Firestore enabled
- Email/Password auth enabled
- FlutterFire configuration generated for this repo

Verify Flutter locally:

```bash
flutter doctor
```

## Install Dependencies

```bash
flutter pub get
```

## Firebase Setup

Run FlutterFire configuration in this repo:

```bash
flutterfire configure
```

This repo currently includes a placeholder [lib/firebase_options.dart](lib/firebase_options.dart). Replace it with the generated file from `flutterfire configure`.

## Firestore Collections

The current app code expects these collections:
- `users`
- `friendships`
- `debts`
- `inbox_items`
- `credit_score_events`
- `users/{uid}/transactions`

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

1. Clone the repo.
2. Run `flutter pub get`.
3. Run `flutterfire configure`.
4. Ensure Firebase Auth Email/Password is enabled.
5. Ensure Firestore is enabled.
6. Start the app with `flutter run`.
7. Create a test account through the signup screen.
8. Log in and verify these flows:
   - add a transaction
   - add a friend request
   - create a debt request
   - open stats
   - open profile and inbox

## Credit Score Note

The app still contains client-driven credit score update logic during debt settlement and overdue handling. For a production-safe deployment, move those writes into Firebase Cloud Functions and lock down Firestore rules so normal clients cannot alter score-sensitive documents directly.

## Validation Commands

Static analysis:

```bash
flutter analyze
```

Tests:

```bash
flutter test
```
