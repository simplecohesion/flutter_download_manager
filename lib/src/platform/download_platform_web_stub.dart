import 'package:dio/dio.dart';
import 'package:flutter_download_manager/src/download_task.dart';
import 'package:flutter_download_manager/src/platform/download_platform_interface.dart';

class WebDownloadPlatform implements DownloadPlatformInterface {
  WebDownloadPlatform(this.dio);
  final Dio dio;

  @override
  Future<void> download({
    required String url,
    required String savePath,
    CancelToken? cancelToken,
    bool forceDownload = false,
  }) async {}

  @override
  Future<DownloadTask?> addDownload(String url, String localPath) async {
    return null;
  }

  @override
  String getFileNameFromUrl(String url) {
    return '';
  }
}
