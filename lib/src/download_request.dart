// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:dio/dio.dart';

class DownloadRequest {
  DownloadRequest(
    this.url,
    this.path,
  );
  final String url;
  final String path;
  CancelToken cancelToken = CancelToken();
  bool forceDownload = false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadRequest &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          path == other.path;

  @override
  int get hashCode => url.hashCode ^ path.hashCode;
}
