import 'dart:async';
import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:universal_io/io.dart';

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
        getDownload(url)?.progress.value =
            (received + partialFileLength) / (total + partialFileLength);

        if (total == -1) {}
      };

  Future<void> download(String url, String savePath, cancelToken,
      {forceDownload = false}) async {
    late String partialFilePath;
    late File partialFile;
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
          var ioSink = partialFile.openWrite(mode: FileMode.writeOnlyAppend);
          var _f = File(partialFilePath + tempExtension);
          await ioSink.addStream(_f.openRead());
          await _f.delete();
          await ioSink.close();
          await partialFile.rename(savePath);

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
      var task = getDownload(url)!;
      if (task.status.value != DownloadStatus.canceled &&
          task.status.value != DownloadStatus.paused) {
        setStatus(task, DownloadStatus.failed);
        runningTasks--;

        if (_queue.isNotEmpty) {
          _startExecution();
        }
        rethrow;
      } else if (task.status.value == DownloadStatus.paused) {
        final ioSink = partialFile.openWrite(mode: FileMode.writeOnlyAppend);
        final f = File(partialFilePath + tempExtension);
        if (await f.exists()) {
          await ioSink.addStream(f.openRead());
        }
        await ioSink.close();
      }
    }

    runningTasks--;

    if (_queue.isNotEmpty) {
      _startExecution();
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

  Future<DownloadTask?> addDownload(String url, String savedDir) async {
    if (url.isNotEmpty) {
      if (savedDir.isEmpty) {
        savedDir = ".";
      }

      var isDirectory = await Directory(savedDir).exists();
      var downloadFilename = isDirectory
          ? savedDir + Platform.pathSeparator + getFileNameFromUrl(url)
          : savedDir;

      return await _addDownloadRequest(DownloadRequest(url, downloadFilename));
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
        _queue.remove(_cache[downloadRequest.url]);
      }
    }

    _queue.add(DownloadRequest(downloadRequest.url, downloadRequest.path));
    var task = DownloadTask(_queue.last);

    _cache[downloadRequest.url] = task;

    _startExecution();

    return task;
  }

  Future<void> pauseDownload(String url) async {
    if (kDebugMode) {
      print("Pause Download");
    }
    var task = getDownload(url)!;
    setStatus(task, DownloadStatus.paused);
    task.request.cancelToken.cancel();

    _queue.remove(task.request);
  }

  Future<void> cancelDownload(String url) async {
    if (kDebugMode) {
      print("Cancel Download");
    }
    var task = getDownload(url)!;
    setStatus(task, DownloadStatus.canceled);
    _queue.remove(task.request);
    task.request.cancelToken.cancel();
  }

  Future<void> resumeDownload(String url) async {
    if (kDebugMode) {
      print("Resume Download");
    }
    var task = getDownload(url)!;
    setStatus(task, DownloadStatus.downloading);
    task.request.cancelToken = CancelToken();
    _queue.add(task.request);

    _startExecution();
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

  Future<DownloadStatus> whenDownloadComplete(String url,
      {Duration timeout = const Duration(hours: 2)}) {
    DownloadTask? task = getDownload(url);

    if (task != null) {
      return task.whenDownloadComplete(timeout: timeout);
    } else {
      return Future.error(ArgumentError("Not found"));
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
    await Future.wait(urls.map((url) => pauseDownload(url)));
  }

  Future<void> cancelBatchDownloads(List<String> urls) async {
    await Future.wait(urls.map((url) => cancelDownload(url)));
  }

  Future<void> resumeBatchDownloads(List<String> urls) async {
    await Future.wait(urls.map((url) => resumeDownload(url)));
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

        if (task.status.value.isCompleted) {
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
    });

    return progress;
  }

  Future<List<DownloadTask?>?> whenBatchDownloadsComplete(List<String> urls,
      {Duration timeout = const Duration(hours: 2)}) {
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
    if (runningTasks == maxConcurrentTasks || _queue.isEmpty) {
      return;
    }

    while (_queue.isNotEmpty && runningTasks < maxConcurrentTasks) {
      runningTasks++;
      if (kDebugMode) {
        print('Concurrent workers: $runningTasks');
      }
      var currentRequest = _queue.removeFirst();

      download(
          currentRequest.url, currentRequest.path, currentRequest.cancelToken);

      await Future.delayed(Duration(milliseconds: 500), null);
    }
  }

  /// This function is used for get file name with extension from url
  String getFileNameFromUrl(String url) {
    if (url.contains('?')) {
      final filename = url.split('?').first.split('/').last;
      print('filename: $filename');
      return filename.contains('.') ? filename : filename + '.mp4';
    }
    final filename = url.split('/').last;
    print('filename: $filename');
    return filename.contains('.') ? filename : filename + '.mp4';
  }
}
