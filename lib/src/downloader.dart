import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:collection/collection.dart';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';

class DownloadManager {
  final Map<String, DownloadTask> _cache = <String, DownloadTask>{};
  final Queue<DownloadRequest> _queue = Queue();
  var dio = Dio();
  static const partialExtension = ".partial";
  static const tempExtension = ".temp";

  int maxConcurrentTasks = 2;
  int runningTasks = 0;

  static final DownloadManager _dm = new DownloadManager._internal();

  DownloadManager._internal();

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

  void Function(int, int) createCallback(url, int partialFileLength) =>
      (int received, int total) {
        // Handle unknown content length (total == -1) to avoid NaN/Infinity
        if (total == -1) {
          // Cannot calculate progress without total size; leave progress unchanged
          // or set to -1 to indicate indeterminate
          return;
        }
        final totalSize = total + partialFileLength;
        if (totalSize > 0) {
          getDownload(url)?.progress.value =
              (received + partialFileLength) / totalSize;
        }
      };

  Future<void> download(String url, String savePath, cancelToken,
      {forceDownload = false}) async {
    String? partialFilePath;
    File? partialFile;
    try {
      var task = getDownload(url);

      if (task == null || task.status.value == DownloadStatus.canceled) {
        return;
      }
      setStatus(task, DownloadStatus.downloading);

      if (kDebugMode) {
        print(url);
      }
      partialFilePath = savePath + partialExtension;
      partialFile = File(partialFilePath);
      await partialFile.parent.create(recursive: true);

      var partialFileExist = await partialFile.exists();

      if (partialFileExist) {
        if (kDebugMode) {
          print("Partial File Exists");
        }

        var partialFileLength = await partialFile.length();

        var response = await dio.download(url, partialFilePath + tempExtension,
            onReceiveProgress: createCallback(url, partialFileLength),
            options: Options(
              headers: {HttpHeaders.rangeHeader: 'bytes=$partialFileLength-'},
            ),
            cancelToken: cancelToken,
            deleteOnError: true);

        if (response.statusCode == HttpStatus.partialContent) {
          // Server supports resume - append temp to partial and finalize
          var ioSink = partialFile.openWrite(mode: FileMode.writeOnlyAppend);
          var tempFile = File(partialFilePath + tempExtension);
          await ioSink.addStream(tempFile.openRead());
          await tempFile.delete();
          await ioSink.close();
          await partialFile.rename(savePath);

          setStatus(task, DownloadStatus.completed);
        } else if (response.statusCode == HttpStatus.ok) {
          // Server doesn't support resume - sent full file, use it instead
          await partialFile.delete();
          var tempFile = File(partialFilePath + tempExtension);
          await tempFile.rename(savePath);

          setStatus(task, DownloadStatus.completed);
        }
      } else {
        var response = await dio.download(url, partialFilePath,
            onReceiveProgress: createCallback(url, 0),
            cancelToken: cancelToken,
            deleteOnError: false);

        if (response.statusCode == HttpStatus.ok) {
          await partialFile.rename(savePath);
          setStatus(task, DownloadStatus.completed);
        }
      }
    } catch (e) {
      var task = getDownload(url);
      if (task == null) {
        rethrow;
      }
      if (task.status.value != DownloadStatus.canceled &&
          task.status.value != DownloadStatus.paused) {
        setStatus(task, DownloadStatus.failed);
        rethrow;
      } else if (task.status.value == DownloadStatus.paused) {
        if (partialFile != null && partialFilePath != null) {
          final ioSink = partialFile.openWrite(mode: FileMode.writeOnlyAppend);
          final f = File(partialFilePath + tempExtension);
          if (await f.exists()) {
            await ioSink.addStream(f.openRead());
          }
          await ioSink.close();
        }
      }
    } finally {
      if (runningTasks > 0) {
        runningTasks--;
      }

      if (_queue.isNotEmpty) {
        _startExecution();
      }
    }
  }

  void setStatus(DownloadTask? task, DownloadStatus status) {
    if (task != null) {
      task.status.value = status;
      if (status == DownloadStatus.completed) {
        task.progress.value = 1.0;
      }
    }
  }

  Future<DownloadTask?> addDownload(String url, String savedDir) async {
    if (url.isNotEmpty) {
      if (savedDir.isEmpty) {
        savedDir = ".";
      }

      var isDirectory = await Directory(savedDir).exists();
      var downloadFilename = isDirectory
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
        // Remove the existing request from queue (not the task itself)
        _queue.remove(_cache[downloadRequest.url]!.request);
      }
    }

    _queue.add(DownloadRequest(downloadRequest.url, downloadRequest.path));
    var task = DownloadTask(_queue.last);

    _cache[downloadRequest.url] = task;

    _startExecution();

    return task;
  }

  Future<bool> pauseDownload(String url) async {
    if (kDebugMode) {
      print("Pause Download");
    }
    var task = getDownload(url);
    if (task == null) {
      return false;
    }
    setStatus(task, DownloadStatus.paused);
    task.request.cancelToken.cancel();

    _queue.remove(task.request);
    return true;
  }

  Future<bool> cancelDownload(String url) async {
    if (kDebugMode) {
      print("Cancel Download");
    }
    var task = getDownload(url);
    if (task == null) {
      return false;
    }
    setStatus(task, DownloadStatus.canceled);
    _queue.remove(task.request);
    task.request.cancelToken.cancel();
    return true;
  }

  Future<bool> resumeDownload(String url) async {
    if (kDebugMode) {
      print("Resume Download");
    }
    var task = getDownload(url);
    if (task == null) {
      return false;
    }
    setStatus(task, DownloadStatus.downloading);
    task.request.cancelToken = CancelToken();
    _queue.add(task.request);

    _startExecution();
    return true;
  }

  Future<bool> removeDownload(String url) async {
    await cancelDownload(url);
    return _cache.remove(url) != null;
  }

  // Do not immediately call getDownload After addDownload, rather use the returned DownloadTask from addDownload
  DownloadTask? getDownload(String url) {
    return _cache[url];
  }

  Future<DownloadStatus> whenDownloadComplete(String url,
      {Duration timeout = const Duration(hours: 2)}) async {
    DownloadTask? task = getDownload(url);

    if (task != null) {
      return task.whenDownloadComplete(timeout: timeout);
    } else {
      return Future.error("Not found");
    }
  }

  List<DownloadTask> getAllDownloads() {
    return _cache.values.toList();
  }

  // Batch Download Mechanism
  Future<List<DownloadTask?>> addBatchDownloads(
      List<String> urls, String savedDir) async {
    var tasks = <DownloadTask?>[];
    for (var url in urls) {
      tasks.add(await addDownload(url, savedDir));
    }
    return tasks;
  }

  List<DownloadTask?> getBatchDownloads(List<String> urls) {
    return urls.map((e) => _cache[e]).toList();
  }

  Future<void> pauseBatchDownloads(List<String> urls) async {
    for (var url in urls) {
      await pauseDownload(url);
    }
  }

  Future<void> cancelBatchDownloads(List<String> urls) async {
    for (var url in urls) {
      await cancelDownload(url);
    }
  }

  Future<void> resumeBatchDownloads(List<String> urls) async {
    for (var url in urls) {
      await resumeDownload(url);
    }
  }

  ValueNotifier<double> getBatchDownloadProgress(List<String> urls) {
    ValueNotifier<double> progress = ValueNotifier(0);
    var total = urls.length;

    if (total == 0) {
      return progress;
    }

    if (total == 1) {
      return getDownload(urls.first)?.progress ?? progress;
    }

    var progressMap = Map<String, double>();

    urls.forEach((url) {
      DownloadTask? task = getDownload(url);

      if (task != null) {
        progressMap[url] = 0.0;

        if (task.status.value == DownloadStatus.completed) {
          progressMap[url] = 1.0;
          progress.value = progressMap.values.sum / total;
        }

        var progressListener;
        progressListener = () {
          progressMap[url] = task.progress.value;
          progress.value = progressMap.values.sum / total;
        };

        task.progress.addListener(progressListener);

        var listener;
        listener = () {
          if (task.status.value.isCompleted) {
            if (task.status.value == DownloadStatus.completed) {
              progressMap[url] = 1.0;
            }
            progress.value = progressMap.values.sum / total;
            task.status.removeListener(listener);
            task.progress.removeListener(progressListener);
          }
        };

        task.status.addListener(listener);
      } else {
        total--;
      }
    });

    return progress;
  }

  Future<List<DownloadTask?>?> whenBatchDownloadsComplete(List<String> urls,
      {Duration timeout = const Duration(hours: 2)}) async {
    var completer = Completer<List<DownloadTask?>?>();

    var completed = 0;
    var total = urls.length;

    urls.forEach((url) {
      DownloadTask? task = getDownload(url);

      if (task != null) {
        if (task.status.value.isCompleted) {
          completed++;

          if (completed == total) {
            completer.complete(getBatchDownloads(urls));
          }
        }

        var listener;
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
    });

    return completer.future.timeout(timeout);
  }

  void _startExecution() async {
    if (runningTasks >= maxConcurrentTasks || _queue.isEmpty) {
      return;
    }

    while (_queue.isNotEmpty && runningTasks < maxConcurrentTasks) {
      runningTasks++;
      if (kDebugMode) {
        print('Concurrent workers: $runningTasks');
      }
      var currentRequest = _queue.removeFirst();

      unawaited(download(currentRequest.url, currentRequest.path,
              currentRequest.cancelToken)
          .catchError((Object _, StackTrace __) {
        // Errors are surfaced through task status; avoid uncaught async errors.
      }));

      await Future.delayed(Duration(milliseconds: 500), null);
    }
  }

  /// This function is used for get file name with extension from url
  String getFileNameFromUrl(String url) {
    return url.split('/').last;
  }
}
