import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'src/web_download_manager.dart';
import 'src/download_manager_platform.dart';

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
