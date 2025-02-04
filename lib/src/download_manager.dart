import 'dart:async';
import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:universal_io/io.dart';

class DownloadManager {
  factory DownloadManager({
    int? maxConcurrentTasks,
    Dio? dio,
  }) {
    if (maxConcurrentTasks != null) {
      _dm.maxConcurrentTasks = maxConcurrentTasks;
    }

    _dm.dio = dio ?? Dio();

    return _dm;
  }

  DownloadManager._internal();
  final Map<String, DownloadTask> _cache = <String, DownloadTask>{};
  final Queue<DownloadRequest> _queue = Queue();
  Dio dio = Dio();
  static const partialExtension = '.partial';
  static const tempExtension = '.temp';

  int maxConcurrentTasks = 2;
  int runningTasks = 0;

  static final DownloadManager _dm = DownloadManager._internal();

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
    late String partialFilePath;
    late File partialFile;

    final task = getDownload(url);
    if (task == null || task.status.value == DownloadStatus.canceled) {
      return;
    }
    setStatus(task, DownloadStatus.downloading);

    debugPrint('download: $url');
    partialFilePath = '$savePath$partialExtension';
    partialFile = File(partialFilePath);

    try {
      final partialFileExist = partialFile.existsSync();

      if (partialFileExist) {
        if (kDebugMode) {
          debugPrint('Partial File Exists');
        }

        final partialFileLength = await partialFile.length();

        final response = await dio.download(
          url,
          partialFilePath + tempExtension,
          onReceiveProgress: createCallback(url, partialFileLength),
          options: Options(
            headers: {HttpHeaders.rangeHeader: 'bytes=$partialFileLength-'},
          ),
          cancelToken: cancelToken,
        );

        if (response.statusCode == HttpStatus.partialContent) {
          final ioSink = partialFile.openWrite(mode: FileMode.writeOnlyAppend);
          final tempFile = File(partialFilePath + tempExtension);
          await ioSink.addStream(tempFile.openRead());
          await tempFile.delete();
          await ioSink.close();
          await partialFile.rename(savePath);

          setStatus(task, DownloadStatus.completed);
        }
      } else {
        final response = await dio.download(
          url,
          partialFilePath,
          onReceiveProgress: createCallback(url, 0),
          cancelToken: cancelToken,
          deleteOnError: false,
        );

        if (response.statusCode == HttpStatus.ok) {
          await partialFile.rename(savePath);
          setStatus(task, DownloadStatus.completed);
        }
      }
    } catch (e) {
      if (task.status.value != DownloadStatus.canceled &&
          task.status.value != DownloadStatus.paused) {
        setStatus(task, DownloadStatus.failed);
        rethrow;
      } else if (task.status.value == DownloadStatus.paused) {
        final ioSink = partialFile.openWrite(mode: FileMode.writeOnlyAppend);
        final tempFile = File(partialFilePath + tempExtension);
        if (tempFile.existsSync()) {
          await ioSink.addStream(tempFile.openRead());
        }
        await ioSink.close();
      }
    } finally {
      runningTasks--;
      if (_queue.isNotEmpty) {
        unawaited(_startExecution());
      }
    }
  }

  void disposeNotifiers(DownloadTask task) {
    task.status.dispose();
    task.progress.dispose();
  }

  void setStatus(DownloadTask? task, DownloadStatus status) {
    if (task != null) {
      task.status.value = status;

      // tasks.add(task);
      // if (status.isCompleted) {
      //   disposeNotifiers(task);
      // }
    }
  }

  Future<DownloadTask?> addDownload(String url, String localPath) async {
    if (url.isNotEmpty) {
      final savedDir = localPath.isEmpty ? '.' : localPath;

      final isDirectory = Directory(savedDir).existsSync();
      final downloadFilename = isDirectory
          ? savedDir + Platform.pathSeparator + getFileNameFromUrl(url)
          : savedDir;

      return _addDownloadRequest(DownloadRequest(url, downloadFilename));
    }
    return null;
  }

  Future<DownloadTask> _addDownloadRequest(
    DownloadRequest downloadRequest,
  ) async {
    if (_cache[downloadRequest.url] != null) {
      if (!_cache[downloadRequest.url]!.status.value.isCompleted &&
          _cache[downloadRequest.url]!.request == downloadRequest) {
        // Do nothing
        return _cache[downloadRequest.url]!;
      } else {
        _queue.remove(_cache[downloadRequest.url]?.request);
      }
    }

    _queue.add(DownloadRequest(downloadRequest.url, downloadRequest.path));
    final task = DownloadTask(_queue.last);

    _cache[downloadRequest.url] = task;

    unawaited(_startExecution());

    return task;
  }

  Future<void> pauseDownload(String url) async {
    debugPrint('Pause Download');
    final task = getDownload(url)!;
    setStatus(task, DownloadStatus.paused);
    task.request.cancelToken.cancel();

    _queue.remove(task.request);
  }

  Future<void> cancelDownload(String url) async {
    debugPrint('Cancel Download');
    final task = getDownload(url)!;
    setStatus(task, DownloadStatus.canceled);
    _queue.remove(task.request);
    task.request.cancelToken.cancel();
  }

  Future<void> resumeDownload(String url) async {
    debugPrint('Resume Download');
    final task = getDownload(url)!;
    setStatus(task, DownloadStatus.downloading);
    task.request.cancelToken = CancelToken();
    _queue.add(task.request);

    unawaited(_startExecution());
  }

  Future<void> removeDownload(String url) async {
    if (_cache.containsKey(url)) {
      await cancelDownload(url);
      _cache.remove(url);
      final task = getDownload(url);
      if (task != null) {
        disposeNotifiers(task);
      }
    }
  }

  // Do not immediately call getDownload After addDownload, rather use the returned DownloadTask from addDownload
  DownloadTask? getDownload(String url) {
    if (_cache.containsKey(url)) {
      return _cache[url];
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
    return _cache.values.toList();
  }

  // Batch Download Mechanism
  Future<void> addBatchDownloads(List<String> urls, String savedDir) async {
    await Future.wait(urls.map((url) => addDownload(url, savedDir)));
  }

  List<DownloadTask?> getBatchDownloads(List<String> urls) {
    return urls.map((e) => _cache[e]).toList();
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

  Future<void> _startExecution() async {
    if (runningTasks == maxConcurrentTasks || _queue.isEmpty) {
      return;
    }

    while (_queue.isNotEmpty && runningTasks < maxConcurrentTasks) {
      runningTasks++;

      debugPrint('Concurrent workers: $runningTasks');

      final currentRequest = _queue.removeFirst();

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

  /// This function is used for get file name with extension from url
  String getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // Return the last segment if available; else fall back to the full URL.
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : url;
    } catch (e) {
      debugPrint('Failed to parse URL: $e');
      return url;
    }
  }
}
