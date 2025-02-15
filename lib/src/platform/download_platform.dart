import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/src/download_manager.dart';
import 'package:flutter_download_manager/src/platform/download_platform_interface.dart';
import 'package:flutter_download_manager/src/platform/download_platform_io.dart';
import 'package:flutter_download_manager/src/platform/download_platform_web_stub.dart'
    if (dart.library.html) 'package:flutter_download_manager/src/platform/download_platform_web.dart';

/// Creates and returns the appropriate download platform implementation based on the current platform.
///
/// This factory function determines whether the application is running on web or other platforms
/// and returns the corresponding platform-specific implementation:
/// - Returns [WebDownloadPlatform] for web platforms
/// - Returns [IODownloadPlatform] for non-web platforms (iOS, Android, desktop)
///
/// Parameters:
///   - [dio]: The Dio HTTP client instance to be used for downloads
///   - [manager]: The DownloadManager instance that will manage the downloads
///
/// Returns a [DownloadPlatformInterface] implementation appropriate for the current platform.
DownloadPlatformInterface createDownloadPlatform(
  Dio dio,
  DownloadManager manager,
) {
  if (kIsWeb) {
    return WebDownloadPlatform(dio: dio, manager: manager);
  } else {
    return IODownloadPlatform(dio: dio, manager: manager);
  }
}
