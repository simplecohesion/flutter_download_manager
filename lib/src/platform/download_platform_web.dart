// ignore_for_file: public_member_api_docs

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
  Future<void> deleteFile(String filePath) async {
    await OpfsHelper.deleteFile(filePath);
  }

  @override
  Future<void> createDirectory(String directoryPath) async {
    await OpfsHelper.getDirectoryHandle(directoryPath, create: true);
  }

  @override
  Future<void> deleteDirectory(String directoryPath) async {
    await OpfsHelper.deleteDirectory(directoryPath);
  }

  @override
  Future<List<String>> getFilesInDirectory(String directoryPath) async {
    final directoryHandle = await OpfsHelper.getDirectoryHandle(directoryPath);
    final directoryHandleExt = directoryHandle as FileSystemDirectoryHandleExt;
    final entries = await directoryHandleExt.values().asStream().toList();

    return entries
        .where((handle) => handle.kind == 'file')
        .cast<FileSystemFileHandle>()
        .map((fileHandle) => fileHandle.name)
        .toList();
  }

  @override
  Future<List<String>> getDirectoriesInDirectory(String directoryPath) async {
    final directoryHandle = await OpfsHelper.getDirectoryHandle(directoryPath);
    final directoryHandleExt = directoryHandle as FileSystemDirectoryHandleExt;
    final entries = await directoryHandleExt.values().asStream().toList();

    return entries
        .where((handle) => handle.kind == 'directory')
        .cast<FileSystemDirectoryHandle>()
        .map((directoryHandle) => directoryHandle.name)
        .toList();
  }

  @override
  Future<String> getQualifiedPathForFile(String filePath) async {
    final fileHandle = await OpfsHelper.getFileHandle(filePath);
    return URL.createObjectURL(fileHandle);
  }
}

extension type FileSystemDirectoryHandleExt._(FileSystemDirectoryHandle _)
    implements FileSystemHandle, JSObject {
  external JsAsyncIterator<FileSystemHandle> values();
}

extension type JsAsyncIterator<T extends JSAny>._(JSObject _)
    implements JSObject {
  external JSPromise<JsAsyncIteratorState<T>> next();

  Stream<T> asStream() async* {
    while (true) {
      final result = await next().toDart;
      if (result.done) break;
      yield result.value;
    }
  }
}

extension type JsAsyncIteratorState<T extends JSAny>._(JSObject _)
    implements JSObject {
  external bool get done;

  external T get value;
}
