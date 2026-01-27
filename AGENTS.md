# Repository Guidelines

## Project Structure & Module Organization
- `lib/`: package API (`lib/flutter_download_manager.dart`) and implementation details in `lib/src/`.
- `example/`: runnable Flutter app demonstrating downloads across platforms.
- `test/`: package tests (`*_test.dart`).
- `files/`: documentation assets (e.g., screenshots referenced by `README.md`).

## Build, Test, and Development Commands
From the repository root:
- `flutter pub get` — install dependencies.
- `dart format .` — format all Dart sources.
- `dart analyze` — static analysis for the package (`analysis_options.yaml` excludes `example/` and `test/`).
- `flutter test` — run tests (note: current tests perform real network downloads and write local files).

Run the demo app:
- `cd example && flutter pub get && flutter run` — launch the example on your selected device.

## Coding Style & Naming Conventions
- Use Dart defaults: 2-space indentation, trailing commas where appropriate, and run `dart format` before pushing.
- Naming: `UpperCamelCase` for types, `lowerCamelCase` for members, `snake_case.dart` for files.
- Keep public surface area minimal: export via `lib/flutter_download_manager.dart`; keep internals in `lib/src/`.

## Testing Guidelines
- Framework: `flutter_test`.
- Prefer deterministic/unit tests (mock `dio` and avoid external URLs). If an integration-style test is needed, document required network/FS access in the test.

## Commit & Pull Request Guidelines
- Commit history mixes imperative summaries and Conventional Commit prefixes (e.g., `chore(deps): ...`). Prefer `feat:`, `fix:`, `chore(deps):` where it fits.
- PRs should include: what/why, platforms tested (Android/iOS/desktop), and any breaking changes. Add screenshots for `example/` UI changes.
- If behavior changes, update `CHANGELOG.md`; if publishing, bump `version:` in `pubspec.yaml`.
