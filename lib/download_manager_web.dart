import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/services.dart';
import 'package:flutter_download_manager/src/download_manager_platform.dart';
import 'package:flutter_download_manager/src/web_download_manager.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Web plugin implementation.
class FlutterDownloadManagerWeb extends WebDownloadManager
    implements DownloadManagerPlatform {
  FlutterDownloadManagerWeb({int? maxConcurrentTasks, dio})
      : super(maxConcurrentTasks: maxConcurrentTasks, dio: dio);

  /// This static function is called by the plugin registrant.
  static void registerWith(Registrar registrar) {
    DownloadManagerPlatform.instance = FlutterDownloadManagerWeb();
  }
}
