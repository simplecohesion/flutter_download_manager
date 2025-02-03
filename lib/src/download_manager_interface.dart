import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';

abstract class DownloadManagerInterface {
  Map<String, DownloadTask> get cache;
  Queue<DownloadRequest> get queue;
  Dio get dio;
  int get maxConcurrentTasks;
  int get runningTasks;

  void Function(int, int) createCallback(String url, int partialFileLength);
  String extractFileName(String url);
  Future<void> download(String url, String savePath, CancelToken cancelToken,
      {bool forceDownload = false});
  Future<DownloadTask?> addDownload(String url, String savedDir);
  Future<void> pauseDownload(String url);
  Future<void> cancelDownload(String url);
  Future<void> resumeDownload(String url);
  Future<void> removeDownload(String url);
  DownloadTask? getDownload(String url);
  List<DownloadTask> getAllDownloads();
  Future<void> addBatchDownloads(List<String> urls, String savedDir);
  // ... other methods
}
