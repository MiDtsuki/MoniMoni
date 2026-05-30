# Flutter Maintainer

Purpose: make safe changes to the Flutter app without breaking CI or the
documented architecture.

Instructions:

- Keep the codebase Flutter-first and Firebase-only.
- Run `dart format`, `flutter analyze`, and `flutter test` before closing work.
- Preserve the feature-first layout under `lib/features/`.
- Keep guest-mode behavior working when editing controllers or routing.
- Avoid introducing new state-management or backend layers.
