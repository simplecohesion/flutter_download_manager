import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:flutter_download_manager/src/platform/download_platform.dart';
import 'package:flutter_download_manager/src/platform/download_platform_interface.dart';

/// A singleton class that manages download tasks with support for concurrent downloads,
/// queue management, and progress tracking.
///
/// The DownloadManager provides functionality to:
/// * Download files with progress tracking
/// * Pause, resume, and cancel downloads
/// * Queue downloads with configurable concurrent task limits
/// * Track multiple download statuses and progress
class DownloadManager {
  DownloadManager._internal({
    int? maxConcurrentTasks,
    Dio? dio,
  }) {
    if (maxConcurrentTasks != null) {
      this.maxConcurrentTasks = maxConcurrentTasks;
    }
    if (dio != null) {
      this.dio = dio;
    }
    _platform = createDownloadPlatform(this.dio, this);
  }

  /// Singleton instance of the DownloadManager
  static final DownloadManager instance = DownloadManager._internal();

  /// Cache of download tasks indexed by URL
  final Map<String, DownloadTask> cache = <String, DownloadTask>{};

  /// Queue of pending download requests
  final Queue<DownloadRequest> queue = Queue();

  /// HTTP client for making download requests
  Dio dio = Dio();

  /// File extension used for partially downloaded files
  final partialExtension = '.partial';

  /// File extension used for temporary files
  final tempExtension = '.temp';

  /// Maximum number of concurrent download tasks
  int maxConcurrentTasks = 2;

  /// Current number of running download tasks
  int runningTasks = 0;

  late final DownloadPlatformInterface _platform;

  /// Creates a progress callback function for a specific download URL
  ///
  /// [url] The URL of the download
  /// [partialFileLength] The length of any existing partial download
  void Function(int, int) createCallback(String url, int partialFileLength) =>
      (int received, int total) {
        getDownload(url)?.progress.value =
            (received + partialFileLength) / (total + partialFileLength);

        if (total == -1) {}
      };

  /// Downloads a file from the given URL to the specified path
  ///
  /// [url] The URL to download from
  /// [savePath] The local path to save the file to
  /// [cancelToken] Optional token to cancel the download
  /// [forceDownload] Whether to force download even if file exists
  Future<void> download(
    String url,
    String savePath,
    CancelToken? cancelToken, {
    bool forceDownload = false,
  }) async {
    return _platform.download(
      url: url,
      savePath: savePath,
      cancelToken: cancelToken,
      forceDownload: forceDownload,
    );
  }

  /// Cleans up ValueNotifier resources for a download task
  void disposeNotifiers(DownloadTask task) {
    task.status.dispose();
    task.progress.dispose();
  }

  /// Updates the status of a download task
  void setStatus(DownloadTask? task, DownloadStatus status) {
    if (task != null) {
      task.status.value = status;
    }
  }

  /// Adds a new download task to the queue
  ///
  /// [url] The URL to download from
  /// [localPath] The local path to save the file to
  ///
  /// Throws [ArgumentError] if URL or localPath is empty or if URL is invalid
  Future<DownloadTask> addDownload(String url, String localPath) async {
    if (url.isEmpty) {
      throw ArgumentError('url cannot be empty');
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw ArgumentError('Invalid URL: $url');
    }

    if (localPath.isEmpty) {
      throw ArgumentError('localPath cannot be empty');
    }

    return _addDownload(DownloadRequest(url, localPath));
  }

  Future<DownloadTask> _addDownload(
    DownloadRequest downloadRequest,
  ) async {
    if (cache[downloadRequest.url] != null) {
      if (!cache[downloadRequest.url]!.status.value.isCompleted &&
          cache[downloadRequest.url]!.request == downloadRequest) {
        // Do nothing
        return cache[downloadRequest.url]!;
      } else {
        queue.remove(cache[downloadRequest.url]?.request);
      }
    }

    queue.add(DownloadRequest(downloadRequest.url, downloadRequest.path));
    final task = DownloadTask(queue.last);

    cache[downloadRequest.url] = task;

    unawaited(startExecution());

    return task;
  }

  /// Pauses an active download
  ///
  /// [url] The URL of the download to pause
  Future<void> pauseDownload(String url) async {
    debugPrint('Pause Download');
    final task = getDownload(url)!;
    setStatus(task, DownloadStatus.paused);
    task.request.cancelToken.cancel();

    queue.remove(task.request);
  }

  /// Cancels a download
  ///
  /// [url] The URL of the download to cancel
  Future<void> cancelDownload(String url) async {
    debugPrint('Cancel Download');
    final task = getDownload(url)!;
    setStatus(task, DownloadStatus.canceled);
    queue.remove(task.request);
    task.request.cancelToken.cancel();
  }

  /// Resumes a paused download
  ///
  /// [url] The URL of the download to resume
  Future<void> resumeDownload(String url) async {
    debugPrint('Resume Download');
    final task = getDownload(url)!;
    setStatus(task, DownloadStatus.downloading);
    task.request.cancelToken = CancelToken();
    queue.add(task.request);

    unawaited(startExecution());
  }

  /// Removes a download from the manager
  ///
  /// [url] The URL of the download to remove
  Future<void> removeDownload(String url) async {
    if (cache.containsKey(url)) {
      await cancelDownload(url);
      cache.remove(url);
      final task = getDownload(url);
      if (task != null) {
        disposeNotifiers(task);
      }
    }
  }

  /// Retrieves a download task by URL
  ///
  /// Note: Do not immediately call this after [addDownload],
  /// instead use the DownloadTask returned by [addDownload]
  ///
  /// [url] The URL of the download to retrieve
  DownloadTask? getDownload(String url) {
    if (cache.containsKey(url)) {
      return cache[url];
    }
    return null;
  }

  /// Waits for a download to complete
  ///
  /// [url] The URL of the download to wait for
  /// [timeout] Maximum time to wait for completion
  Future<DownloadStatus> whenDownloadComplete(
    String url, {
    Duration timeout = const Duration(hours: 2),
  }) {
    final task = getDownload(url);

    if (task != null) {
      return task.whenDownloadComplete(timeout: timeout);
    } else {
      return Future.error(ArgumentError('Not found'));
    }
  }

  /// Returns all active downloads
  List<DownloadTask> getAllDownloads() {
    return cache.values.toList();
  }

  /// Returns download tasks for the specified URLs
  List<DownloadTask?> getDownloads(List<String> urls) {
    return urls.map((e) => cache[e]).toList();
  }

  /// Pauses multiple downloads
  Future<void> pauseDownloads(List<String> urls) async {
    await Future.wait(urls.map(pauseDownload));
  }

  /// Cancels multiple downloads
  Future<void> cancelDownloads(List<String> urls) async {
    await Future.wait(urls.map(cancelDownload));
  }

  /// Resumes multiple downloads
  Future<void> resumeDownloads(List<String> urls) async {
    await Future.wait(urls.map(resumeDownload));
  }

  /// Creates a ValueNotifier that tracks the combined progress of multiple downloads
  ///
  /// [urls] List of URLs to track
  /// Returns a ValueNotifier with values from 0.0 to 1.0
  ValueNotifier<double> getDownloadsProgress(List<String> urls) {
    final progress = ValueNotifier<double>(0);
    var total = urls.length;

    if (total == 0) {
      return progress;
    }

    if (total == 1) {
      return getDownload(urls.first)?.progress ?? progress;
    }

    final progressMap = <String, double>{};

    for (final url in urls) {
      final task = getDownload(url);

      if (task != null) {
        progressMap[url] = 0.0;

        if (task.status.value.isCompleted) {
          progressMap[url] = 1.0;
          progress.value = progressMap.values.sum / total;
        }

        void Function() progressListener;
        progressListener = () {
          progressMap[url] = task.progress.value;
          progress.value = progressMap.values.sum / total;
        };

        task.progress.addListener(progressListener);

        late void Function() listener;
        listener = () {
          if (task.status.value.isCompleted) {
            progressMap[url] = 1.0;
            progress.value = progressMap.values.sum / total;
            task.status.removeListener(listener);
            task.progress.removeListener(progressListener);
          }
        };

        task.status.addListener(listener);
      } else {
        total--;
      }
    }

    return progress;
  }

  /// Waits for multiple downloads to complete
  ///
  /// [urls] List of URLs to wait for
  /// [timeout] Maximum time to wait for completion
  Future<List<DownloadTask?>?> whenDownloadsComplete(
    List<String> urls, {
    Duration timeout = const Duration(hours: 2),
  }) {
    final completer = Completer<List<DownloadTask?>?>();

    var completed = 0;
    var total = urls.length;

    for (final url in urls) {
      final task = getDownload(url);

      if (task != null) {
        if (task.status.value.isCompleted) {
          completed++;

          if (completed == total) {
            completer.complete(getDownloads(urls));
          }
        }

        late void Function() listener;
        listener = () {
          if (task.status.value.isCompleted) {
            completed++;

            if (completed == total) {
              completer.complete(getDownloads(urls));
              task.status.removeListener(listener);
            }
          }
        };

        task.status.addListener(listener);
      } else {
        total--;

        if (total == 0) {
          completer.complete(null);
        }
      }
    }

    return completer.future.timeout(timeout);
  }

  /// Starts executing queued downloads up to the maximum concurrent task limit
  Future<void> startExecution() async {
    if (runningTasks == maxConcurrentTasks || queue.isEmpty) {
      return;
    }

    while (queue.isNotEmpty && runningTasks < maxConcurrentTasks) {
      runningTasks++;

      debugPrint('Concurrent workers: $runningTasks');

      final currentRequest = queue.removeFirst();

      unawaited(
        download(
          currentRequest.url,
          currentRequest.path,
          currentRequest.cancelToken,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  /// File system operations

  /// Deletes a file at the specified path
  Future<void> deleteFile(String path) async {
    return _platform.deleteFile(path);
  }

  /// Creates a directory at the specified path
  Future<void> createDirectory(String path) async {
    return _platform.createDirectory(path);
  }

  /// Deletes a directory at the specified path
  Future<void> deleteDirectory(String path) async {
    return _platform.deleteDirectory(path);
  }

  /// Lists all files in a directory
  Future<List<String>> getFilesInDirectory(String path) {
    return _platform.getFilesInDirectory(path);
  }

  /// Lists all directories in a directory
  Future<List<String>> getDirectoriesInDirectory(String path) {
    return _platform.getDirectoriesInDirectory(path);
  }

  /// Gets the qualified path for a file
  Future<String> getQualifiedPathForFile(String path) {
    return _platform.getQualifiedPathForFile(path);
  }
}
