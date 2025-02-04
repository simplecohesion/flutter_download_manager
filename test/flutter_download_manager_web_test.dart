// ignore_for_file: library_annotations, prefer_asserts_with_message, cascade_invocations

@Timeout(Duration(seconds: 60))
@TestOn('chrome')

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const url1 =
      'https://www.sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4';

  const url2 = 'https://www.sample-videos.com/img/Sample-jpg-image-1mb.jpg';
  const url3 = 'https://www.sample-videos.com/zip/10mb.zip';

  const fileName1 = 'test1.mp4';
  const fileName2 = 'test2.jpg';
  const fileName3 = 'test3.zip';

  final directory1 = Directory('./test/downloads1');
  final directory2 = Directory('./test/downloads2');
  final directory3 = Directory('./test/downloads3');
  final directory4 = Directory('./test/downloads4');
  final directory5 = Directory('./test/downloads5');
  final directory6 = Directory('./test/downloads6');
  final directory7 = Directory('./test/downloads7');
  setUpAll(() {
    try {
      if (directory1.existsSync()) {
        directory1.deleteSync(recursive: true);
      }
      if (directory2.existsSync()) {
        directory2.deleteSync(recursive: true);
      }
      if (directory3.existsSync()) {
        directory3.deleteSync(recursive: true);
      }
      if (directory4.existsSync()) {
        directory4.deleteSync(recursive: true);
      }
      if (directory5.existsSync()) {
        directory5.deleteSync(recursive: true);
      }
      if (directory6.existsSync()) {
        directory6.deleteSync(recursive: true);
      }
      if (directory7.existsSync()) {
        directory7.deleteSync(recursive: true);
      }

      // Create the directories
      directory1.createSync(recursive: true);
      directory2.createSync(recursive: true);
      directory3.createSync(recursive: true);
      directory4.createSync(recursive: true);
      directory5.createSync(recursive: true);
      directory6.createSync(recursive: true);
      directory7.createSync(recursive: true);
    } catch (e) {
      debugPrint(e.toString());
    }
  });

  tearDownAll(() {
    try {
      directory1.deleteSync(recursive: true);
      directory2.deleteSync(recursive: true);
      directory3.deleteSync(recursive: true);
      directory4.deleteSync(recursive: true);
      directory5.deleteSync(recursive: true);
      directory6.deleteSync(recursive: true);
      directory7.deleteSync(recursive: true);
    } catch (e) {
      debugPrint(e.toString());
    }
  });

  group('download manager', () {
    test('single download with progress', () async {
      final dl = DownloadManager.instance;

      final task = await dl.addDownload(
        url1,
        directory1.path + Platform.pathSeparator + fileName1,
      );

      final statuses = <DownloadStatus>[];
      final progresses = <double>[];

      task.status.addListener(() {
        statuses.add(task.status.value);
      });

      task.progress.addListener(() {
        progresses.add(task.progress.value);
      });

      final status = await dl.whenDownloadComplete(url1);
      assert(status == DownloadStatus.completed);

      assert(statuses.contains(DownloadStatus.completed));
      assert(progresses.contains(1.0));
    });

    test('cancel download', () async {
      final dl = DownloadManager.instance;

      final task = await dl.addDownload(
        url1,
        directory2.path + Platform.pathSeparator + fileName1,
      );

      await Future<void>.delayed(const Duration(seconds: 1));
      await dl.cancelDownload(url1);

      assert(task.status.value == DownloadStatus.canceled);
    });

    test('pause and resume download', () async {
      final dl = DownloadManager.instance;

      await dl.addDownload(
        url3,
        directory3.path + Platform.pathSeparator + fileName3,
      );

      await Future<void>.delayed(const Duration(seconds: 2));
      await dl.pauseDownload(url3);

      await Future<void>.delayed(const Duration(seconds: 1));
      await dl.resumeDownload(url3);

      final status = await dl.whenDownloadComplete(url3);

      assert(status == DownloadStatus.completed);
    });

    test('handle empty url', () async {
      try {
        final dl = DownloadManager.instance;

        const url = '';
        await dl.addDownload(
          url,
          directory4.path + Platform.pathSeparator + fileName1,
        );
      } catch (e) {
        assert(e is ArgumentError);
      }
    });

    test('handle empty path', () async {
      try {
        final dl = DownloadManager.instance;

        const path = '';
        await dl.addDownload(
          url1,
          path,
        );
      } catch (e) {
        assert(e is ArgumentError);
      }
    });

    test('download in sequence', () async {
      final dl = DownloadManager.instance;

      await dl.addDownload(
        url1,
        directory5.path + Platform.pathSeparator + fileName1,
      );
      await dl.addDownload(
        url2,
        directory5.path + Platform.pathSeparator + fileName2,
      );
      await dl.addDownload(
        url3,
        directory5.path + Platform.pathSeparator + fileName3,
      );

      final status1 = await dl.whenDownloadComplete(url1);
      final status2 = await dl.whenDownloadComplete(url2);
      final status3 = await dl.whenDownloadComplete(url3);

      assert(status1 == DownloadStatus.completed);
      assert(status2 == DownloadStatus.completed);
      assert(status3 == DownloadStatus.completed);
    });

    test('cancel a batched download', () async {
      final dl = DownloadManager.instance;

      final urls = <String>[];
      urls.add(url1);
      urls.add(url2);
      urls.add(url3);

      await dl.addDownload(
        url1,
        directory6.path + Platform.pathSeparator + fileName1,
      );
      await dl.addDownload(
        url2,
        directory6.path + Platform.pathSeparator + fileName2,
      );
      await dl.addDownload(
        url3,
        directory6.path + Platform.pathSeparator + fileName3,
      );

      final downloads = dl.getDownloads(urls);

      await dl.cancelDownloads(urls);

      await dl.whenDownloadsComplete(urls);
      assert(
        downloads
            .every((task) => task?.status.value == DownloadStatus.canceled),
      );
    });

    test('cancel a single item in a batched download', () async {
      final dl = DownloadManager.instance;

      final urls = <String>[];
      urls.add(url1);
      urls.add(url2);
      urls.add(url3);

      await dl.addDownload(
        url1,
        directory7.path + Platform.pathSeparator + fileName1,
      );
      await dl.addDownload(
        url2,
        directory7.path + Platform.pathSeparator + fileName2,
      );
      await dl.addDownload(
        url3,
        directory7.path + Platform.pathSeparator + fileName3,
      );

      final downloads = dl.getDownloads(urls);

      await Future<void>.delayed(const Duration(seconds: 1));

      await dl.cancelDownload(url3);

      await dl.whenDownloadsComplete(urls);
      assert(downloads[0]?.status.value == DownloadStatus.completed);
      assert(downloads[1]?.status.value == DownloadStatus.completed);
      debugPrint('status: ${downloads[2]?.status.value}');
      assert(downloads[2]?.status.value == DownloadStatus.canceled);
    });

    test('delete file', () async {
      final dl = DownloadManager.instance;

      final task = await dl.addDownload(
        url2,
        directory1.path + Platform.pathSeparator + fileName2,
      );

      await task.whenDownloadComplete();

      await dl.deleteFile(
        directory1.path + Platform.pathSeparator + fileName2,
      );

      assert(
        !File(directory1.path + Platform.pathSeparator + fileName2)
            .existsSync(),
      );
    });

    test('delete directory', () async {
      final dl = DownloadManager.instance;
    });
  });
}
