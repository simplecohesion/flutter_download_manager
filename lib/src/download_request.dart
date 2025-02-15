// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:dio/dio.dart';

/// A class that represents a file download request.
///
/// This class encapsulates all the necessary information needed to perform
/// a file download operation, including the source URL and destination path.
class DownloadRequest {
  /// Creates a new download request.
  ///
  /// [url] The source URL from which the file will be downloaded.
  /// [path] The destination path where the downloaded file will be saved.
  DownloadRequest(
    this.url,
    this.path,
  );

  /// The URL from which the file will be downloaded.
  final String url;

  /// The local path where the downloaded file will be saved.
  final String path;

  /// A token that can be used to cancel the download operation.
  ///
  /// This token can be passed to the download manager to cancel
  /// an ongoing download.
  CancelToken cancelToken = CancelToken();

  /// Whether to force the download even if the file already exists.
  ///
  /// If set to `true`, the file will be downloaded again even if it
  /// already exists at the destination path. Default is `false`.
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
