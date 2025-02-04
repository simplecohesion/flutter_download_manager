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
    partialFilePath = '$savePath${manager.partialExtension}';
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
          partialFilePath + manager.tempExtension,
          onReceiveProgress: manager.createCallback(url, partialFileLength),
          options: Options(
            headers: {HttpHeaders.rangeHeader: 'bytes=$partialFileLength-'},
          ),
          cancelToken: cancelToken,
        );

        if (response.statusCode == HttpStatus.partialContent) {
          final ioSink = partialFile.openWrite(mode: FileMode.writeOnlyAppend);
          final tempFile = File(partialFilePath + manager.tempExtension);
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
        final tempFile = File(partialFilePath + manager.tempExtension);
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

  @override
  Future<void> deleteFile(String path) async {
    if (path.isEmpty) {
      return;
    }
    final file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  @override
  Future<void> createDirectory(String path) async {
    if (path.isEmpty) {
      return;
    }
    final directory = Directory(path);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
  }

  @override
  Future<void> deleteDirectory(String path) async {
    if (path.isEmpty) {
      return;
    }
    final directory = Directory(path);
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  }

  @override
  Future<List<String>> getFilesInDirectory(String path) async {
    if (path.isEmpty) {
      return [];
    }
    final directory = Directory(path);
    if (!directory.existsSync()) {
      return [];
    }
    return directory.listSync().map((e) => e.path).toList();
  }
}
