import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:dio/dio.dart';
import 'package:file_system_access_api/file_system_access_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/src/download_manager.dart';
import 'package:flutter_download_manager/src/download_status.dart';
import 'package:flutter_download_manager/src/platform/download_platform_interface.dart';
import 'package:flutter_download_manager/src/opfs_helpers.dart';

class WebDownloadPlatform implements DownloadPlatformInterface {
  WebDownloadPlatform({
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
    final task = manager.getDownload(url);
    if (task == null || task.status.value == DownloadStatus.canceled) {
      return;
    }
    manager.setStatus(task, DownloadStatus.downloading);

    debugPrint('download: $url');

    try {
      final response = await dio.get<Uint8List>(
        url,
        options: Options(responseType: ResponseType.bytes),
        cancelToken: cancelToken,
      );

      final data = response.data;

      if (response.statusCode == html.HttpStatus.ok && data != null) {
        await OpfsHelper.writeFile(data, savePath);
        manager.setStatus(task, DownloadStatus.completed);
      } else {
        manager.setStatus(task, DownloadStatus.failed);
      }
    } catch (e) {
      if (task.status.value != DownloadStatus.canceled &&
          task.status.value != DownloadStatus.paused) {
        manager.setStatus(task, DownloadStatus.failed);
        rethrow;
      } else if (task.status.value == DownloadStatus.paused) {
        manager.setStatus(task, DownloadStatus.paused);
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
    final fileHandle = await OpfsHelper.getFileHandle(path);
    await fileHandle.remove();
  }

  @override
  Future<void> createDirectory(String path) async {
    await OpfsHelper.getDirectoryHandle(path, create: true);
  }

  @override
  Future<void> deleteDirectory(String path) async {
    final directoryHandle = await OpfsHelper.getDirectoryHandle(path);
    await directoryHandle.remove(recursive: true);
  }

  @override
  Future<List<String>> getFilesInDirectory(String path) async {
    final directoryHandle = await OpfsHelper.getDirectoryHandle(path);

    final files = await directoryHandle.values
        .where((handle) => handle.kind == FileSystemKind.file)
        .cast<FileSystemFileHandle>()
        .asyncMap(
          (fileHandle) async =>
              html.Url.createObjectUrlFromBlob(await fileHandle.getFile()),
        )
        .toList();

    return files;
  }
}
