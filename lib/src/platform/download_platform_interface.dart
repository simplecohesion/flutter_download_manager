import 'package:dio/dio.dart';

abstract class DownloadPlatformInterface {
  Future<void> download({
    required String url,
    required String savePath,
    CancelToken? cancelToken,
    bool forceDownload = false,
  });

  Future<void> deleteFile(String path);

  Future<void> createDirectory(String path);

  Future<void> deleteDirectory(String path);

  Future<List<String>> getFilesInDirectory(String path);
}
