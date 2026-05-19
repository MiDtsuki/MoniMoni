# Moni Agent Notes

## Backend

Moni now uses Firebase only:
- Firebase Auth for authentication
- Cloud Firestore for remote data
- Drift scaffolding exists locally, but Firebase is the active backend

## Active Collections

- `users`
- `friendships`
- `debts`
- `inbox_items`
- `credit_score_events`
- `users/{uid}/transactions`

## Important App Rules

- Username search uses prefix matching on `username_lower`
- Credit score currently updates from app-side Firestore transactions
- For production hardening, move credit score mutations into Cloud Functions and lock down Firestore rules
- Guest mode remains local-only

## Development Notes

- Do not reintroduce any non-Firebase backend
- Keep profile, transaction, debt, and inbox field names consistent with current Firestore usage
- If FlutterFire config is missing, run `flutterfire configure`
