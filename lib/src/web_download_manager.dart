import 'dart:async';
import 'dart:collection';
import 'dart:js_interop';
import 'package:file_system_access_api/file_system_access_api.dart';
import 'package:universal_io/io.dart';
import 'dart:html' as html;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'download_manager_interface.dart';
import 'download_manager_platform.dart';

class WebDownloadManager extends DownloadManagerPlatform {
  WebDownloadManager({int? maxConcurrentTasks, Dio? dio})
      : super(maxConcurrentTasks: maxConcurrentTasks, dio: dio);

  @override
  final Map<String, DownloadTask> cache = <String, DownloadTask>{};
  @override
  final Queue<DownloadRequest> queue = Queue();

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

  Future<void> _downloadFile(Uint8List data, String filename) async {
    try {
      final fileSystem = await html.window.navigator.storage?.getDirectory();
      if (fileSystem != null) {
        final fileHandle =
            await fileSystem.getFileHandle(filename, create: true);
        final writable =
            await fileHandle.createWritable() as FileSystemWritableFileStream;
        await writable.write(data.toJS).toDart;
        await writable.close().toDart;
      } else {
        throw Exception('Could not access file system');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('File write error: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> download(String url, String savePath, CancelToken cancelToken,
      {bool forceDownload = false}) async {
    // Implement your web-specific download logic here.
  }

  @override
  Future<DownloadTask?> addDownload(String url, String savedDir) async {
    // Implement web addDownload logic.
  }

  @override
  Future<void> pauseDownload(String url) async {
    // Implement web pauseDownload logic.
  }

  @override
  Future<void> cancelDownload(String url) async {
    // Implement web cancelDownload logic.
  }

  @override
  Future<void> resumeDownload(String url) async {
    // Implement web resumeDownload logic.
  }

  @override
  Future<void> removeDownload(String url) async {
    // Implement web removeDownload logic.
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

/// This is a bridge to interact with the web's OPFS writable stream via JavaScript interop.
///
@JS()
@staticInterop
class FileSystemWritableFileStream {}

extension FileSystemWritableFileStreamExtension
    on FileSystemWritableFileStream {
  external JSPromise write(JSAny data);
  external JSPromise close();
}
