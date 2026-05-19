# Moni Workspace Notes

## Current Architecture

The app is Firebase-backed:
- Firebase Auth handles signup, login, signout, and password reset email flow
- Cloud Firestore stores users, transactions, friendships, debts, inbox items, and credit score events
- Drift is still present locally but is not the primary runtime backend

## Current Query Model

- User profiles live in `users/{uid}`
- Transactions live in `users/{uid}/transactions/{transactionId}`
- Friendships live in `friendships/{friendshipId}`
- Debts live in `debts/{debtId}`
- Inbox items live in `inbox_items/{itemId}`
- Credit score events live in `credit_score_events/{eventId}`

## Constraints

- Keep the app pure Firebase
- Do not add another backend
- Username search must remain prefix-based through `username_lower`
- Keep guest mode working offline

## Follow-Up Work

- Replace placeholder `lib/firebase_options.dart` with generated FlutterFire config
- Add Firestore Security Rules
- Move score-sensitive writes into Cloud Functions
- Add production Firebase indexes if Firestore prompts for them
