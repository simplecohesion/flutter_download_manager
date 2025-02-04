import 'package:dio/dio.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';

abstract class DownloadPlatformInterface {
  Future<DownloadTask?> addDownload(
    String url,
    String localPath,
  );

  Future<void> download({
    required String url,
    required String savePath,
    CancelToken? cancelToken,
    bool forceDownload = false,
  });
}
