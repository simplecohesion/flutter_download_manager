import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';

class DownloadTask {
  final DownloadRequest request;
  ValueNotifier<DownloadStatus> status = ValueNotifier(DownloadStatus.queued);
  ValueNotifier<double> progress = ValueNotifier(0);

  DownloadTask(
    this.request,
  );

  Future<DownloadStatus> whenDownloadComplete(
      {Duration timeout = const Duration(hours: 2)}) async {
    // If already in a terminal state, return immediately
    if (status.value.isCompleted) {
      return status.value;
    }

    var completer = Completer<DownloadStatus>();

    void listener() {
      if (status.value.isCompleted && !completer.isCompleted) {
        completer.complete(status.value);
        status.removeListener(listener);
      }
    }

    status.addListener(listener);

    return completer.future.timeout(timeout);
  }
}
