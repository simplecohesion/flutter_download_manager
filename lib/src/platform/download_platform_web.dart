import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
// ignore: avoid_web_libraries_in_flutter
import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/src/download_manager.dart';
import 'package:flutter_download_manager/src/download_status.dart';
import 'package:flutter_download_manager/src/platform/download_platform_interface.dart';
import 'package:flutter_download_manager/src/platform/opfs_helpers.dart';
import 'package:web/web.dart' hide ResponseType;

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
      final response = await dio.get<ResponseBody>(
        url,
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );

      final responseStream = response.data?.stream;

      if (response.statusCode == HttpStatus.ok && responseStream != null) {
        final fileHandle = await OpfsHelper.getFileHandle(savePath);
        final opfsWritableFileStream = await fileHandle.createWritable().toDart;
        final opfsWriter = opfsWritableFileStream.getWriter();

        // make a future out the the responseStream
        final completer = Completer<void>();
        final subscription = responseStream.listen(
          (data) {
            opfsWriter.write(data.toJS).toDart;
          },
          onDone: () {
            opfsWriter.close().toDart;
            manager.setStatus(task, DownloadStatus.completed);
            completer.complete();
          },
          onError: (Object error, StackTrace stackTrace) {
            opfsWriter.close().toDart;
            manager.setStatus(task, DownloadStatus.failed);
            completer.completeError(error, stackTrace);
          },
          cancelOnError: true,
        );

        await completer.future;
        await subscription.cancel();
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
    await OpfsHelper.deleteFile(path);
  }

  @override
  Future<void> createDirectory(String path) async {
    await OpfsHelper.getDirectoryHandle(path, create: true);
  }

  @override
  Future<void> deleteDirectory(String path) async {
    await OpfsHelper.deleteDirectory(path);
  }

  @override
  Future<List<String>> getFilesInDirectory(String path) async {
    final directoryHandle = await OpfsHelper.getDirectoryHandle(path);

    final entries = directoryHandle
        .getProperty<JSArray<FileSystemHandle>>('entries'.toJS)
        .toDart;

    final fileFutures = entries
        .where((handle) => handle.kind == 'file')
        .cast<FileSystemFileHandle>()
        .map(
          (fileHandle) async => URL
              .createObjectURL((await fileHandle.getFile().toDart) as JSObject),
        )
        .toList();

    return Future.wait(fileFutures);
  }

  @override
  Future<List<String>> getDirectoriesInDirectory(String path) async {
    final directoryHandle = await OpfsHelper.getDirectoryHandle(path);

    final entries = directoryHandle
        .getProperty<JSArray<FileSystemHandle>>('entries'.toJS)
        .toDart;

    return entries
        .where((handle) => handle.kind == 'directory')
        .cast<FileSystemDirectoryHandle>()
        .map((directoryHandle) => directoryHandle.name)
        .toList();
  }
}
