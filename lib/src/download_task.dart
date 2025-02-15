import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';

/// Represents a single download operation with its associated request, status, and progress.
///
/// A [DownloadTask] is created for each download request and maintains the current state
/// of the download through [status] and [progress] notifiers.
class DownloadTask {
  /// Creates a new download task for the given [request].
  DownloadTask(
    this.request,
  );

  /// The original download request containing the URL and other download parameters.
  final DownloadRequest request;

  /// A notifier that holds the current status of the download.
  ///
  /// The status can be monitored for changes to track the download's lifecycle.
  /// Initial status is [DownloadStatus.queued].
  final ValueNotifier<DownloadStatus> status =
      ValueNotifier(DownloadStatus.queued);

  /// A notifier that holds the current progress of the download.
  ///
  /// Values range from 0.0 to 1.0, representing the percentage of completion.
  final ValueNotifier<double> progress = ValueNotifier(0);

  /// Waits for the download to complete and returns the final [DownloadStatus].
  ///
  /// This method returns a [Future] that completes when the download reaches a terminal
  /// status (success or failure). If the download doesn't complete within the specified
  /// [timeout] duration, a [TimeoutException] is thrown.
  ///
  /// Parameters:
  ///   * [timeout]: Maximum duration to wait for download completion.
  ///     Defaults to 2 hours.
  Future<DownloadStatus> whenDownloadComplete({
    Duration timeout = const Duration(hours: 2),
  }) async {
    final completer = Completer<DownloadStatus>();

    if (status.value.isCompleted) {
      completer.complete(status.value);
    }

    void Function()? listener;
    listener = () {
      debugPrint('listener: $status');
      if (status.value.isCompleted) {
        completer.complete(status.value);
        status.removeListener(listener!);
      }
    };

    status.addListener(listener);

    return completer.future.timeout(timeout);
  }

  /// Returns a string representation of the download task.
  ///
  /// Includes the task's identity hash code, URL, current status, and progress.
  @override
  String toString() =>
      'DownloadTask#${hashCode.toRadixString(16)}(url: ${request.url}, status: ${status.value}, progress: ${progress.value})';
}
