# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Development Commands

```bash
# Install dependencies
flutter pub get

# Format code
dart format .

# Static analysis (excludes example/ and test/ via analysis_options.yaml)
dart analyze

# Run tests (note: tests perform real network downloads and write local files)
flutter test

# Run a single test
flutter test test/flutter_download_manager_test.dart

# Run the example app
cd example && flutter pub get && flutter run
```

## Architecture

This is a Flutter package providing a cross-platform file download manager with parallel and batch download support.

### Core Classes

- **DownloadManager** (`lib/src/downloader.dart`): Singleton that manages all downloads. Uses a queue-based system with configurable concurrency (`maxConcurrentTasks`, default 2). Handles partial downloads via `.partial` and `.temp` file extensions for resume support.

- **DownloadTask** (`lib/src/download_task.dart`): Represents a single download with `ValueNotifier<DownloadStatus>` for status and `ValueNotifier<double>` for progress (0.0-1.0). Use `whenDownloadComplete()` to await completion.

- **DownloadRequest** (`lib/src/download_request.dart`): Holds URL, save path, and Dio `CancelToken` for a download. Equality based on URL + path.

- **DownloadStatus** (`lib/src/download_status.dart`): Enum with states: `queued`, `downloading`, `completed`, `failed`, `paused`, `canceled`. The `isCompleted` extension returns true for terminal states (completed, failed, canceled).

### Key Implementation Details

- Uses Dio for HTTP requests with Range header support for resumable downloads
- Downloads are keyed by URL in an internal cache (`_cache`)
- Partial downloads append to existing `.partial` files; completed downloads are renamed to final path
- Batch operations iterate over URL lists and delegate to single-download methods

## Coding Conventions

- Public API exported via `lib/flutter_download_manager.dart`; internals stay in `lib/src/`
- Use `dart format` before committing
- Commit messages: prefer Conventional Commit prefixes (`feat:`, `fix:`, `chore(deps):`)
- Update `CHANGELOG.md` for behavior changes; bump `version:` in `pubspec.yaml` when publishing
