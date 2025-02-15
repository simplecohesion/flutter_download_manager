/// Represents the current status of a download operation.
enum DownloadStatus {
  /// Download is queued but not yet started
  queued,

  /// Download is currently in progress
  downloading,

  /// Download has successfully completed
  completed,

  /// Download has failed due to an error
  failed,

  /// Download has been paused by the user
  paused,

  /// Download has been canceled by the user
  canceled
}

/// Extension methods for [DownloadStatus]
extension DownloadStatusExtension on DownloadStatus {
  /// Returns true if the download has reached a terminal state
  /// (completed, failed, or canceled).
  bool get isCompleted {
    switch (this) {
      case DownloadStatus.queued:
        return false;
      case DownloadStatus.downloading:
        return false;
      case DownloadStatus.paused:
        return false;
      case DownloadStatus.completed:
        return true;
      case DownloadStatus.failed:
        return true;
      case DownloadStatus.canceled:
        return true;
    }
  }
}
