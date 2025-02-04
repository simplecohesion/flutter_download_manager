import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:flutter_download_manager/src/platform/download_platform_interface.dart';

class IODownloadPlatform implements DownloadPlatformInterface {
  IODownloadPlatform({
    required this.dio,
    required this.manager,
  });
  final Dio dio;
  final DownloadManager manager;

  static const partialExtension = '.partial';
  static const tempExtension = '.temp';

  @override
  Future<DownloadTask?> addDownload(String url, String localPath) async {
    if (url.isEmpty) return null;

    final savedDir = localPath.isEmpty ? '.' : localPath;
    final isDirectory = Directory(savedDir).existsSync();
    final downloadFilename = isDirectory
        ? savedDir + Platform.pathSeparator + getFileNameFromUrl(url)
        : savedDir;

    return manager.addDownloadRequest(DownloadRequest(url, downloadFilename));
  }

  // Future<DownloadTask> _addDownloadRequest(
  //   DownloadRequest downloadRequest,
  // ) async {
  //   if (manager.cache[downloadRequest.url] != null) {
  //     if (!manager.cache[downloadRequest.url]!.status.value.isCompleted &&
  //         manager.cache[downloadRequest.url]!.request == downloadRequest) {
  //       // Do nothing
  //       return manager.cache[downloadRequest.url]!;
  //     } else {
  //       manager.queue.remove(manager.cache[downloadRequest.url]?.request);
  //     }
  //   }

  //   manager.queue
  //       .add(DownloadRequest(downloadRequest.url, downloadRequest.path));
  //   final task = DownloadTask(manager.queue.last);

  //   manager.cache[downloadRequest.url] = task;

  //   unawaited(manager.startExecution());

  //   return task;
  // }

  @override
  Future<void> download({
    required String url,
    required String savePath,
    CancelToken? cancelToken,
    bool forceDownload = false,
  }) async {
    late String partialFilePath;
    late File partialFile;

    final task = manager.getDownload(url);
    if (task == null || task.status.value == DownloadStatus.canceled) {
      return;
    }
    manager.setStatus(task, DownloadStatus.downloading);

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
          onReceiveProgress: manager.createCallback(url, partialFileLength),
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

          manager.setStatus(task, DownloadStatus.completed);
        }
      } else {
        final response = await dio.download(
          url,
          partialFilePath,
          onReceiveProgress: manager.createCallback(url, 0),
          cancelToken: cancelToken,
          deleteOnError: false,
        );

        if (response.statusCode == HttpStatus.ok) {
          await partialFile.rename(savePath);
          manager.setStatus(task, DownloadStatus.completed);
        }
      }
    } catch (e) {
      if (task.status.value != DownloadStatus.canceled &&
          task.status.value != DownloadStatus.paused) {
        manager.setStatus(task, DownloadStatus.failed);
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
      manager.runningTasks--;
      if (manager.queue.isNotEmpty) {
        unawaited(manager.startExecution());
      }
    }
  }
}
