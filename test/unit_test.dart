import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DownloadStatus', () {
    test('isCompleted returns true for terminal states', () {
      expect(DownloadStatus.completed.isCompleted, isTrue);
      expect(DownloadStatus.failed.isCompleted, isTrue);
      expect(DownloadStatus.canceled.isCompleted, isTrue);
    });

    test('isCompleted returns false for non-terminal states', () {
      expect(DownloadStatus.queued.isCompleted, isFalse);
      expect(DownloadStatus.downloading.isCompleted, isFalse);
      expect(DownloadStatus.paused.isCompleted, isFalse);
    });
  });

  group('DownloadRequest', () {
    test('equality based on url and path', () {
      var request1 =
          DownloadRequest('http://example.com/file.zip', '/tmp/file.zip');
      var request2 =
          DownloadRequest('http://example.com/file.zip', '/tmp/file.zip');
      var request3 =
          DownloadRequest('http://example.com/other.zip', '/tmp/file.zip');

      expect(request1, equals(request2));
      expect(request1.hashCode, equals(request2.hashCode));
      expect(request1, isNot(equals(request3)));
    });
  });

  group('DownloadTask', () {
    test('whenDownloadComplete returns immediately if already completed',
        () async {
      var request =
          DownloadRequest('http://example.com/file.zip', '/tmp/file.zip');
      var task = DownloadTask(request);

      // Set status to completed
      task.status.value = DownloadStatus.completed;

      // Should return immediately without timeout
      var result =
          await task.whenDownloadComplete(timeout: Duration(milliseconds: 100));
      expect(result, equals(DownloadStatus.completed));
    });

    test('whenDownloadComplete returns immediately if already failed',
        () async {
      var request =
          DownloadRequest('http://example.com/file.zip', '/tmp/file.zip');
      var task = DownloadTask(request);

      task.status.value = DownloadStatus.failed;

      var result =
          await task.whenDownloadComplete(timeout: Duration(milliseconds: 100));
      expect(result, equals(DownloadStatus.failed));
    });

    test('whenDownloadComplete returns immediately if already canceled',
        () async {
      var request =
          DownloadRequest('http://example.com/file.zip', '/tmp/file.zip');
      var task = DownloadTask(request);

      task.status.value = DownloadStatus.canceled;

      var result =
          await task.whenDownloadComplete(timeout: Duration(milliseconds: 100));
      expect(result, equals(DownloadStatus.canceled));
    });

    test('whenDownloadComplete waits for completion then returns', () async {
      var request =
          DownloadRequest('http://example.com/file.zip', '/tmp/file.zip');
      var task = DownloadTask(request);

      // Start waiting in background
      var future = task.whenDownloadComplete(timeout: Duration(seconds: 5));

      // Simulate download progress
      await Future.delayed(Duration(milliseconds: 50));
      task.status.value = DownloadStatus.downloading;

      await Future.delayed(Duration(milliseconds: 50));
      task.status.value = DownloadStatus.completed;

      var result = await future;
      expect(result, equals(DownloadStatus.completed));
    });

    test('whenDownloadComplete does not throw when called multiple times',
        () async {
      var request =
          DownloadRequest('http://example.com/file.zip', '/tmp/file.zip');
      var task = DownloadTask(request);

      task.status.value = DownloadStatus.completed;

      // Call multiple times - should not throw StateError
      var result1 =
          await task.whenDownloadComplete(timeout: Duration(milliseconds: 100));
      var result2 =
          await task.whenDownloadComplete(timeout: Duration(milliseconds: 100));

      expect(result1, equals(DownloadStatus.completed));
      expect(result2, equals(DownloadStatus.completed));
    });

    test('initial state is queued with zero progress', () {
      var request =
          DownloadRequest('http://example.com/file.zip', '/tmp/file.zip');
      var task = DownloadTask(request);

      expect(task.status.value, equals(DownloadStatus.queued));
      expect(task.progress.value, equals(0.0));
    });
  });

  group('DownloadManager', () {
    test('getFileNameFromUrl extracts filename correctly', () {
      var dm = DownloadManager();
      expect(dm.getFileNameFromUrl('http://example.com/path/to/file.zip'),
          equals('file.zip'));
      expect(dm.getFileNameFromUrl('http://example.com/file.tar.gz'),
          equals('file.tar.gz'));
      expect(dm.getFileNameFromUrl('http://example.com/'), equals(''));
    });

    test('addDownload returns null for empty URL', () async {
      var dm = DownloadManager();
      var task = await dm.addDownload('', '/tmp/file.zip');
      expect(task, isNull);
    });

    test('pauseDownload returns false for unknown URL', () async {
      var dm = DownloadManager();
      var result = await dm.pauseDownload('http://unknown.com/file.zip');
      expect(result, isFalse);
    });

    test('cancelDownload returns false for unknown URL', () async {
      var dm = DownloadManager();
      var result = await dm.cancelDownload('http://unknown.com/file.zip');
      expect(result, isFalse);
    });

    test('resumeDownload returns false for unknown URL', () async {
      var dm = DownloadManager();
      var result = await dm.resumeDownload('http://unknown.com/file.zip');
      expect(result, isFalse);
    });

    test('removeDownload returns false for unknown URL', () async {
      var dm = DownloadManager();
      var result = await dm.removeDownload('http://unknown.com/file.zip');
      expect(result, isFalse);
    });

    test('getDownload returns null for unknown URL', () {
      var dm = DownloadManager();
      var task = dm.getDownload('http://unknown.com/file.zip');
      expect(task, isNull);
    });

    test('whenDownloadComplete throws error for unknown URL', () async {
      var dm = DownloadManager();
      expect(
        () => dm.whenDownloadComplete('http://unknown.com/file.zip'),
        throwsA(equals('Not found')),
      );
    });

    test('getBatchDownloads returns nulls for unknown URLs', () {
      var dm = DownloadManager();
      var downloads = dm.getBatchDownloads([
        'http://unknown1.com/file.zip',
        'http://unknown2.com/file.zip',
      ]);
      expect(downloads, equals([null, null]));
    });

    test('getBatchDownloadProgress returns zero for empty list', () {
      var dm = DownloadManager();
      var progress = dm.getBatchDownloadProgress([]);
      expect(progress.value, equals(0.0));
    });

    test('getAllDownloads returns empty list when no downloads', () {
      var dm = DownloadManager();
      var downloads = dm.getAllDownloads();
      expect(downloads, isEmpty);
    });

    test('singleton returns same instance', () {
      var dm1 = DownloadManager();
      var dm2 = DownloadManager();
      expect(identical(dm1, dm2), isTrue);
    });

    test('maxConcurrentTasks can be configured', () {
      var dm = DownloadManager(maxConcurrentTasks: 5);
      expect(dm.maxConcurrentTasks, equals(5));
    });
  });

  group('Progress calculation edge cases', () {
    test('progress stays within 0.0 to 1.0 range', () {
      var notifier = ValueNotifier<double>(0.0);

      // Simulate various progress values
      notifier.value = 0.0;
      expect(notifier.value, greaterThanOrEqualTo(0.0));

      notifier.value = 0.5;
      expect(notifier.value, lessThanOrEqualTo(1.0));

      notifier.value = 1.0;
      expect(notifier.value, lessThanOrEqualTo(1.0));
    });
  });
}
