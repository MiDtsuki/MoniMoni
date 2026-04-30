# AGENTS.md

## Project
Moni is a Flutter finance app for mobile and web.

## Current Scope
Build frontend only.
No backend.
No Firebase.
No Supabase.
No database.
Use in-memory Riverpod state.

## Tech Stack
- Flutter
- Riverpod
- GoRouter
- fl_chart
- intl
- uuid
- lucide_icons_flutter

## Architecture
Use clean architecture style:

- presentation: screens, widgets, navigation
- application: Riverpod controllers/state
- domain: models/entities/business rules
- data: keep empty or mock-only for now

## Main Features
1. Income and expense logging
2. Debt tracking between friends
3. Statistics with pie charts
4. Profile dashboard
5. Inbox/notifications for friend/debt/settlement requests

## Rules
- Keep UI polished and production-like.
- Keep all state in Riverpod.
- Do not add backend code unless requested.
- Do not hardcode UI inside main.dart.
- Use reusable widgets.
- Use responsive layouts for web and mobile.
- Validate forms properly.
- Amount fields must accept numbers only.
- Date fields should default to current system date/time.
- Use mock users and mock data where needed.

## Design Direction
Modern finance dashboard style:
- rounded cards
- soft green primary color
- clean white/light background
- simple icons
- clear charts
- mobile-first layout
- monochrome color scheme
- only necessary text with suitable colors