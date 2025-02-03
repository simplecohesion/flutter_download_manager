import 'package:dio/dio.dart';
import 'download_task.dart';
import 'download_request.dart';
import 'native_download_manager.dart'; // Default (native) implementation

abstract class DownloadManagerPlatform {
  int maxConcurrentTasks;
  var dio;

  DownloadManagerPlatform({this.maxConcurrentTasks = 2, Dio? dio})
      : dio = dio ?? Dio();

  Future<void> download(String url, String savePath, CancelToken cancelToken,
      {bool forceDownload = false});
  Future<DownloadTask?> addDownload(String url, String savedDir);
  Future<void> pauseDownload(String url);
  Future<void> cancelDownload(String url);
  Future<void> resumeDownload(String url);
  Future<void> removeDownload(String url);

  // You can add more abstract methods matching your API here.

  // Default instance (set to native download manager)
  static DownloadManagerPlatform _instance = NativeDownloadManager();

  static DownloadManagerPlatform get instance => _instance;
  static set instance(DownloadManagerPlatform instance) {
    _instance = instance;
  }
}
