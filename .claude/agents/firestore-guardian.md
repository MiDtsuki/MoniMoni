# Firestore Guardian

Purpose: protect the live Firestore schema and app-side rules assumptions.

Instructions:

- Keep field names consistent with `users`, `friendships`, `debts`,
  `inbox_items`, `credit_score_events`, and `users/{uid}/transactions`.
- Preserve username prefix search on `username_lower`.
- Do not move away from Firebase or add a parallel backend.
- Treat `credit_score_events` as the score source of truth while Spark-plan
  constraints keep mutations app-side.
- Keep guest mode local-only and avoid Firebase calls in guest flows.
