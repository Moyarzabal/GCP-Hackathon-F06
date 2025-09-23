# Repository Guidelines

## Project Structure & Modules
- `lib/` contains the Flutter app: `core/` for config/services, `features/` for screen logic, and `shared/` for reusable models, providers, and widgets; keep feature code self-contained.
- Tests mirror the app in `test/` (unit/widget) and `integration_test/` (end-to-end).
- `functions/` hosts Node.js Cloud Functions managed via `firebase.json`; run npm scripts from within that folder.
- `adk_backend/` houses the Vertex AI FastAPI service with pytest suites, and `scripts/` offers Firestore seeders after `pip install -r scripts/requirements.txt`.

## Build, Test & Development
- Bootstrap dependencies with `flutter pub get` and `cd functions && npm install`.
- Run `flutter analyze`, then launch locally using `flutter run -d chrome` or another device id.
- Build targets with `flutter build web --release`, `flutter build appbundle --release`, and `flutter build ios --release`.
- Start the Firebase emulator through `npm run serve`, deploy with `npm run deploy`, and seed demo data via `python3 scripts/bulk_insert_fridge_products.py` once credentials exist.

## Coding Style & Naming Conventions
- Follow `package:flutter_lints` (`analysis_options.yaml`) and format using `dart format` (2-space indent, trailing commas).
- Use `PascalCase` for widgets/providers, `snake_case.dart` filenames, and `lowerCamelCase` members; prefer `final` and centralise Riverpod providers in `shared/providers`.
- Keep state, data, and presentation code grouped inside each feature folder.

## Testing Guidelines
- Name specs `<subject>_test.dart` and store them beside their feature peers.
- Run `flutter test` before pushing and add `flutter test --coverage` when logic changes; review `coverage/lcov.info` before sharing.
- Execute integration suites with `flutter test integration_test`, ideally while the Firebase emulator runs.
- Grow Cloud Functions coverage with `firebase-functions-test`, reusing fixtures from the Python seeders.

## Commit & Pull Request Guidelines
- Use conventional headers (`feat(fridge): …`, `docs: …`, `refactor(fridge-ui): …`) capped near 72 characters.
- Detail motivation, verification commands (`flutter analyze`, `flutter test`, emulator runs), and attach UI screenshots for visual changes.
- Link issues, call out config/schema adjustments, and update `docs/` plus `.env.example` when environment variables shift.

## Security & Configuration
- Store secrets only in `.env` and `firebase-service-account.json`; never commit live credentials and rotate demo keys quickly.
- Export `GOOGLE_APPLICATION_CREDENTIALS` when running Functions or seed scripts, ideally with per-developer service accounts.
- Version Firebase rules/configs with the code and capture deployment notes in `docs/` so environments stay reproducible.
