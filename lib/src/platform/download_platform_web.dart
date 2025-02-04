import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:flutter_download_manager/src/platform/download_platform_interface.dart';
import 'package:flutter_download_manager/src/platform/opfs_helpers.dart';

class WebDownloadPlatform implements DownloadPlatformInterface {
  WebDownloadPlatform({
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

    try {
      final fileName = getFileNameFromUrl(url);

      return manager.addDownloadRequest(DownloadRequest(url, fileName));
    } catch (e) {
      return null;
    }
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
}
