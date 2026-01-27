# Flutter Download Manager

## Project Overview

**Flutter Download Manager** is a cross-platform (Linux, MacOS, Windows, Android, iOS) file downloader package for Flutter applications. It provides a robust way to manage file downloads with support for:

*   **Resumable Downloads:** Pause and resume functionality using partial files.
*   **Parallel Downloads:** Configurable concurrency (defaults to 2 concurrent tasks) with a queue system.
*   **Batch Operations:** Add, monitor, and control multiple downloads simultaneously.
*   **State Management:** Reactive status and progress updates using `ValueNotifier`.

## getting Started

### Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_download_manager: any
```

### Basic Usage

The core entry point is the `DownloadManager` class. It follows a singleton-like pattern (factory constructor returns the same internal instance).

```dart
import 'package:flutter_download_manager/flutter_download_manager.dart';

void main() async {
  var dl = DownloadManager();
  var url = "https://example.com/file.zip";
  var savedDir = "/path/to/save";

  // Add a download task
  DownloadTask? task = await dl.addDownload(url, savedDir);

  // Listen for progress updates (0.0 to 1.0)
  task?.progress.addListener(() {
    print("Progress: ${task.progress.value}");
  });

  // Listen for status changes (queued, downloading, completed, etc.)
  task?.status.addListener(() {
    print("Status: ${task.status.value}");
  });

  // Wait for completion
  await dl.whenDownloadComplete(url);
}
```

## Architecture & Core Concepts

### `DownloadManager`

The central controller for all download operations. It maintains a queue of `DownloadRequest` objects and a cache of active `DownloadTask`s.

*   **Concurrency:** Controlled by `maxConcurrentTasks` (default: 2). The manager automatically starts queued tasks as slots become available.
*   **Persistence:** Currently, the manager does *not* persist state across app restarts. It uses temporary files (`.partial`, `.temp`) for resumable downloads.

### `DownloadTask`

Represents a single download operation.

*   `status`: A `ValueNotifier<DownloadStatus>` (queued, downloading, completed, failed, paused, canceled).
*   `progress`: A `ValueNotifier<double>` representing the download percentage.
*   `request`: Contains the URL and destination path.

## Key API Methods

| Method | Description |
| :--- | :--- |
| `addDownload(url, savedDir)` | Adds a single file to the download queue. Returns `Future<DownloadTask?>`. |
| `pauseDownload(url)` | Pauses an active download. |
| `resumeDownload(url)` | Resumes a paused download. |
| `cancelDownload(url)` | Cancels a download and removes it from the queue. |
| `getDownload(url)` | Retrieves an existing `DownloadTask` for a given URL. |
| `whenDownloadComplete(url)` | Returns a `Future` that completes when the specific download finishes. |
| `addBatchDownloads(urls, savedDir)` | Adds multiple files to the download queue at once. |
| `getBatchDownloadProgress(urls)` | Returns a `ValueNotifier<double>` for the aggregate progress of a list of URLs. |

## running the Example

The project includes a comprehensive example app in the `example/` directory.

1.  Navigate to the example folder:
    ```bash
    cd example
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the app:
    ```bash
    flutter run
    ```

The example app demonstrates single file downloads, batch downloads, pausing/resuming, and UI integration with `ValueListenableBuilder`.

## Development

### Project Structure

*   `lib/`: Core package source code.
    *   `src/downloader.dart`: Main `DownloadManager` logic.
    *   `src/download_task.dart`: Task state management.
*   `example/`: Flutter example application.
*   `test/`: Unit tests.

### Testing and Linting

*   **Run Tests:**
    ```bash
    flutter test
    ```
*   **Analyze Code:**
    ```bash
    flutter analyze
    ```
