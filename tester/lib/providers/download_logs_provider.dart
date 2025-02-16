import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'download_logs_provider.g.dart';

@riverpod
class DownloadLogs extends _$DownloadLogs {
  @override
  String build() {
    return '';
  }

  Future<DownloadTask> addDownload(String url, String downloadPath) async {
    final downloadManager = DownloadManager.instance;

    final task = await downloadManager.addDownload(url, downloadPath);

    // task.status.addListener(() {
    //   state = task.status.value.toString();
    // });

    return task;
  }
}
