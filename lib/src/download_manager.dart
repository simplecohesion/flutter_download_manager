import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:flutter_download_manager/src/platform/download_platform.dart';
import 'package:flutter_download_manager/src/platform/download_platform_interface.dart';

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

  static final DownloadManager instance = DownloadManager._internal();

  final Map<String, DownloadTask> cache = <String, DownloadTask>{};
  final Queue<DownloadRequest> queue = Queue();

  Dio dio = Dio();

  static const partialExtension = '.partial';
  static const tempExtension = '.temp';

  int maxConcurrentTasks = 2;
  int runningTasks = 0;

  late final DownloadPlatformInterface _platform;

  void Function(int, int) createCallback(String url, int partialFileLength) =>
      (int received, int total) {
        getDownload(url)?.progress.value =
            (received + partialFileLength) / (total + partialFileLength);

        if (total == -1) {}
      };

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

  void disposeNotifiers(DownloadTask task) {
    task.status.dispose();
    task.progress.dispose();
  }

  void setStatus(DownloadTask? task, DownloadStatus status) {
    if (task != null) {
      task.status.value = status;
    }
  }

  Future<DownloadTask?> addDownload(String url, String localPath) async {
    return _platform.addDownload(url, localPath);
  }

  Future<DownloadTask> addDownloadRequest(
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

  Future<void> pauseDownload(String url) async {
    debugPrint('Pause Download');
    final task = getDownload(url)!;
    setStatus(task, DownloadStatus.paused);
    task.request.cancelToken.cancel();

    queue.remove(task.request);
  }

  Future<void> cancelDownload(String url) async {
    debugPrint('Cancel Download');
    final task = getDownload(url)!;
    setStatus(task, DownloadStatus.canceled);
    queue.remove(task.request);
    task.request.cancelToken.cancel();
  }

  Future<void> resumeDownload(String url) async {
    debugPrint('Resume Download');
    final task = getDownload(url)!;
    setStatus(task, DownloadStatus.downloading);
    task.request.cancelToken = CancelToken();
    queue.add(task.request);

    unawaited(startExecution());
  }

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

  // Do not immediately call getDownload After addDownload, rather use the returned DownloadTask from addDownload
  DownloadTask? getDownload(String url) {
    if (cache.containsKey(url)) {
      return cache[url];
    }
    return null;
  }

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

  List<DownloadTask> getAllDownloads() {
    return cache.values.toList();
  }

  // Batch Download Mechanism
  Future<void> addBatchDownloads(List<String> urls, String savedDir) async {
    await Future.wait(urls.map((url) => addDownload(url, savedDir)));
  }

  List<DownloadTask?> getBatchDownloads(List<String> urls) {
    return urls.map((e) => cache[e]).toList();
  }

  Future<void> pauseBatchDownloads(List<String> urls) async {
    await Future.wait(urls.map(pauseDownload));
  }

  Future<void> cancelBatchDownloads(List<String> urls) async {
    await Future.wait(urls.map(cancelDownload));
  }

  Future<void> resumeBatchDownloads(List<String> urls) async {
    await Future.wait(urls.map(resumeDownload));
  }

  ValueNotifier<double> getBatchDownloadProgress(List<String> urls) {
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

  Future<List<DownloadTask?>?> whenBatchDownloadsComplete(
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
            completer.complete(getBatchDownloads(urls));
          }
        }

        late void Function() listener;
        listener = () {
          if (task.status.value.isCompleted) {
            completed++;

            if (completed == total) {
              completer.complete(getBatchDownloads(urls));
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
}

String getFileNameFromUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : url;
  } catch (e) {
    return url;
  }
}
