import 'package:dio/dio.dart';
import 'package:flutter_download_manager/src/download_manager.dart';
import 'package:flutter_download_manager/src/platform/download_platform_interface.dart';

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
    throw UnimplementedError('This is a stub implementation');
  }

  @override
  Future<void> deleteFile(String path) async {
    throw UnimplementedError('This is a stub implementation');
  }

  @override
  Future<void> createDirectory(String path) async {
    throw UnimplementedError('This is a stub implementation');
  }

  @override
  Future<void> deleteDirectory(String path) async {
    throw UnimplementedError('This is a stub implementation');
  }

  @override
  Future<List<String>> getFilesInDirectory(String path) async {
    throw UnimplementedError('This is a stub implementation');
  }

  @override
  Future<List<String>> getDirectoriesInDirectory(String path) async {
    throw UnimplementedError('This is a stub implementation');
  }
}
