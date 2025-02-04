import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/src/download_manager.dart';
import 'package:flutter_download_manager/src/platform/download_platform_interface.dart';
import 'package:flutter_download_manager/src/platform/download_platform_io.dart';
import 'package:flutter_download_manager/src/platform/download_platform_web_stub.dart'
    if (dart.library.html) 'package:flutter_download_manager/src/platform/download_platform_web.dart';

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
