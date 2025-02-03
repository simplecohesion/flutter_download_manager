import 'dart:async';
import 'dart:collection';
import 'package:universal_io/io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'download_manager_interface.dart';

class NativeDownloadManager implements DownloadManagerInterface {
  @override
  final Map<String, DownloadTask> cache = <String, DownloadTask>{};
  @override
  final Queue<DownloadRequest> queue = Queue();
  @override
  var dio = Dio();

  @override
  int maxConcurrentTasks = 2;
  @override
  int runningTasks = 0;

  static const partialExtension = ".partial";
  static const tempExtension = ".temp";

  @override
  void Function(int, int) createCallback(String url, int partialFileLength) =>
      (int received, int total) {
        getDownload(url)?.progress.value =
            (received + partialFileLength) / (total + partialFileLength);
      };

  @override
  String extractFileName(String url) {
    final uri = Uri.parse(url);
    return uri.pathSegments.last;
  }

  @override
  Future<void> download(String url, String savePath, CancelToken cancelToken,
      {bool forceDownload = false}) async {
    late String partialFilePath;
    late File partialFile;

    try {
      var task = getDownload(url);

      if (task == null || task.status.value == DownloadStatus.canceled) {
        return;
      }

      _setStatus(task, DownloadStatus.downloading);

      partialFilePath = savePath + partialExtension;
      partialFile = File(partialFilePath);

      var partialFileExist = await partialFile.exists();

      if (partialFileExist) {
        var partialFileLength = await partialFile.length();

        var response = await dio.download(
          url,
          partialFilePath + tempExtension,
          onReceiveProgress: createCallback(url, partialFileLength),
          options: Options(
            headers: {HttpHeaders.rangeHeader: 'bytes=$partialFileLength-'},
          ),
          cancelToken: cancelToken,
          deleteOnError: true,
        );

        if (response.statusCode == HttpStatus.partialContent) {
          var ioSink = partialFile.openWrite(mode: FileMode.writeOnlyAppend);
          var tempFile = File(partialFilePath + tempExtension);
          await ioSink.addStream(tempFile.openRead());
          await tempFile.delete();
          await ioSink.close();
          await partialFile.rename(savePath);
          _setStatus(task, DownloadStatus.completed);
        }
      } else {
        var response = await dio.download(
          url,
          partialFilePath,
          onReceiveProgress: createCallback(url, 0),
          cancelToken: cancelToken,
          deleteOnError: false,
        );

        if (response.statusCode == HttpStatus.ok) {
          await partialFile.rename(savePath);
          _setStatus(task, DownloadStatus.completed);
        } else {
          _setStatus(task, DownloadStatus.failed);
        }
      }
    } catch (e) {
      var task = getDownload(url)!;
      if (task.status.value != DownloadStatus.canceled &&
          task.status.value != DownloadStatus.paused) {
        _setStatus(task, DownloadStatus.failed);
      } else if (task.status.value == DownloadStatus.paused) {
        try {
          final ioSink = partialFile.openWrite(mode: FileMode.writeOnlyAppend);
          final tempFile = File(partialFilePath + tempExtension);
          if (await tempFile.exists()) {
            await ioSink.addStream(tempFile.openRead());
          }
          await ioSink.close();
          await tempFile.delete();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Pause cleanup error: $e');
          }
        }
      }
      rethrow;
    } finally {
      runningTasks--;
      if (queue.isNotEmpty) {
        _startExecution();
      }
    }
  }

  @override
  Future<DownloadTask?> addDownload(String url, String savedDir) async {
    if (url.isEmpty) return null;

    if (savedDir.isEmpty) {
      savedDir = ".";
    }

    var isDirectory = await Directory(savedDir).exists();
    var downloadFilename = isDirectory
        ? savedDir + Platform.pathSeparator + extractFileName(url)
        : savedDir;

    return _addDownloadRequest(DownloadRequest(url, downloadFilename));
  }

  Future<DownloadTask> _addDownloadRequest(
      DownloadRequest downloadRequest) async {
    if (cache[downloadRequest.url] != null) {
      if (!cache[downloadRequest.url]!.status.value.isCompleted &&
          cache[downloadRequest.url]!.request == downloadRequest) {
        return cache[downloadRequest.url]!;
      } else {
        queue.remove(cache[downloadRequest.url]);
      }
    }

    queue.add(downloadRequest);
    var task = DownloadTask(queue.last);
    cache[downloadRequest.url] = task;
    _startExecution();
    return task;
  }

  void _startExecution() async {
    if (runningTasks == maxConcurrentTasks || queue.isEmpty) {
      return;
    }

    while (queue.isNotEmpty && runningTasks < maxConcurrentTasks) {
      runningTasks++;
      var currentRequest = queue.removeFirst();
      download(
          currentRequest.url, currentRequest.path, currentRequest.cancelToken);
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  void _setStatus(DownloadTask? task, DownloadStatus status) {
    if (task != null) {
      task.status.value = status;
    }
  }

  @override
  Future<void> pauseDownload(String url) async {
    var task = getDownload(url)!;
    _setStatus(task, DownloadStatus.paused);
    task.request.cancelToken.cancel();
    queue.remove(task.request);
  }

  @override
  Future<void> cancelDownload(String url) async {
    var task = getDownload(url)!;
    _setStatus(task, DownloadStatus.canceled);
    queue.remove(task.request);
    task.request.cancelToken.cancel();
  }

  @override
  Future<void> resumeDownload(String url) async {
    var task = getDownload(url)!;
    _setStatus(task, DownloadStatus.downloading);
    task.request.cancelToken = CancelToken();
    queue.add(task.request);
    _startExecution();
  }

  @override
  Future<void> removeDownload(String url) async {
    await cancelDownload(url);
    cache.remove(url);
  }

  @override
  DownloadTask? getDownload(String url) {
    return cache[url];
  }

  @override
  List<DownloadTask> getAllDownloads() {
    return cache.values.toList();
  }

  @override
  Future<void> addBatchDownloads(List<String> urls, String savedDir) async {
    for (final url in urls) {
      try {
        await addDownload(url, savedDir);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to add batch download $url: $e');
        }
      }
    }
  }
}
