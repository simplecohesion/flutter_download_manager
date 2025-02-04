import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';

class DownloadTask {
  DownloadTask(
    this.request,
  );
  final DownloadRequest request;
  final ValueNotifier<DownloadStatus> status =
      ValueNotifier(DownloadStatus.queued);
  final ValueNotifier<double> progress = ValueNotifier(0);

  Future<DownloadStatus> whenDownloadComplete({
    Duration timeout = const Duration(hours: 2),
  }) async {
    final completer = Completer<DownloadStatus>();

    if (status.value.isCompleted) {
      completer.complete(status.value);
    }

    void Function()? listener;
    listener = () {
      print('listener: $status');
      if (status.value.isCompleted) {
        completer.complete(status.value);
        status.removeListener(listener!);
      }
    };

    status.addListener(listener);

    return completer.future.timeout(timeout);
  }

  @override
  String toString() =>
      'DownloadTask#${hashCode.toRadixString(16)}(url: ${request.url}, status: ${status.value}, progress: ${progress.value})';
}
