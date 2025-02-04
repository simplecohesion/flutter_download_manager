import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:dio/dio.dart';
import 'package:file_system_access_api/file_system_access_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:flutter_download_manager/src/platform/download_platform_interface.dart';

class WebDownloadPlatform implements DownloadPlatformInterface {
  WebDownloadPlatform(this.dio) {
    _initializeFileSystem();
  }
  final Dio dio;
  FileSystemDirectoryHandle? _root;

  Future<void> _initializeFileSystem() async {
    _root = await html.window.navigator.storage?.getDirectory();
    if (_root == null) {
      throw Exception('Failed to initialize Origin Private File System');
    }
  }

  @override
  Future<DownloadTask?> addDownload(String url, String localPath) async {
    if (_root == null) await _initializeFileSystem();

    if (url.isEmpty) return null;

    final fileName = getFileNameFromUrl(url);
    // Create or get file handle from OPFS
    final fileHandle = await _root!.getFileHandle(fileName, create: true);

    // Create download request with web-specific path handling
    final request = DownloadRequest(url, fileName);
    return DownloadTask(request);
  }

  @override
  Future<void> download({
    required String url,
    required String savePath,
    CancelToken? cancelToken,
    bool forceDownload = false,
  }) async {
    if (_root == null) await _initializeFileSystem();

    final fileName = getFileNameFromUrl(savePath);
    final fileHandle = await _root!.getFileHandle(fileName, create: true);

    try {
      // Download file using Dio
      final response = await dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
        cancelToken: cancelToken,
      );

      // Write to OPFS
      final writable = await fileHandle.createWritable();
      // await writable.writeAsBytes(response.data);
      await writable.close();
    } catch (e) {
      debugPrint('Error downloading file: $e');
      rethrow;
    }
  }

  @override
  String getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : url;
    } catch (e) {
      debugPrint('Failed to parse URL: $e');
      return url;
    }
  }
}
