import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:flutter_test/flutter_test.dart';

typedef DownloadBehavior = Future<Response<dynamic>> Function({
  required String urlPath,
  required dynamic savePath,
  ProgressCallback? onReceiveProgress,
  CancelToken? cancelToken,
});

class FakeDio extends DioForNative {
  FakeDio(this._behavior);

  final DownloadBehavior _behavior;

  @override
  Future<Response> download(
    String urlPath,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    FileAccessMode fileAccessMode = FileAccessMode.write,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  }) {
    return _behavior(
      urlPath: urlPath,
      savePath: savePath,
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
  }
}

Future<void> _resetManager(DownloadManager dm) async {
  final existing = List<DownloadTask>.from(dm.getAllDownloads());
  for (final task in existing) {
    await dm.removeDownload(task.request.url);
  }
  dm.runningTasks = 0;
}

Future<Response<dynamic>> _okDownload({
  required String urlPath,
  required dynamic savePath,
  ProgressCallback? onReceiveProgress,
  CancelToken? cancelToken,
  bool reportProgress = false,
  int total = 3,
}) async {
  final file = File(savePath as String);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(const [1, 2, 3]);
  if (reportProgress) {
    onReceiveProgress?.call(3, total);
  }
  return Response<dynamic>(
    requestOptions: RequestOptions(path: urlPath),
    statusCode: HttpStatus.ok,
  );
}

void main() {
  group('download manager regressions', () {
    late Directory tempDir;
    late DownloadManager dm;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fdm-regression-');
      dm = DownloadManager(
        maxConcurrentTasks: 1,
        dio: FakeDio(
          ({
            required urlPath,
            required savePath,
            onReceiveProgress,
            cancelToken,
          }) =>
              _okDownload(urlPath: urlPath, savePath: savePath),
        ),
      );
      await _resetManager(dm);
    });

    tearDown(() async {
      await _resetManager(dm);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('batch progress should not treat failed task as fully complete',
        () async {
      dm.maxConcurrentTasks = 0;
      final firstUrl = 'https://example.com/success.bin';
      final secondUrl = 'https://example.com/failure.bin';

      final firstTask = await dm.addDownload(firstUrl, tempDir.path);
      final secondTask = await dm.addDownload(secondUrl, tempDir.path);

      firstTask!.status.value = DownloadStatus.completed;
      secondTask!.status.value = DownloadStatus.failed;

      final progress = dm.getBatchDownloadProgress([firstUrl, secondUrl]);

      expect(progress.value, 0.5);
    });

    test('completed download should set progress to 1.0', () async {
      dm.maxConcurrentTasks = 1;
      dm.dio = FakeDio(
        ({
          required urlPath,
          required savePath,
          onReceiveProgress,
          cancelToken,
        }) =>
            _okDownload(urlPath: urlPath, savePath: savePath),
      );

      final url = 'https://example.com/no-progress-callback.bin';
      final task = await dm.addDownload(url, tempDir.path);
      final status =
          await task!.whenDownloadComplete(timeout: const Duration(seconds: 2));

      expect(status, DownloadStatus.completed);
      expect(task.progress.value, 1.0);
    });

    test('unknown content length should still end at 1.0 progress', () async {
      dm.maxConcurrentTasks = 1;
      dm.dio = FakeDio(
        ({
          required urlPath,
          required savePath,
          onReceiveProgress,
          cancelToken,
        }) =>
            _okDownload(
          urlPath: urlPath,
          savePath: savePath,
          reportProgress: true,
          total: -1,
          onReceiveProgress: onReceiveProgress,
        ),
      );

      final url = 'https://example.com/unknown-total.bin';
      final task = await dm.addDownload(url, tempDir.path);
      final status =
          await task!.whenDownloadComplete(timeout: const Duration(seconds: 2));

      expect(status, DownloadStatus.completed);
      expect(task.progress.value, 1.0);
    });

    test('scheduler should not emit uncaught async errors on download failure',
        () async {
      dm.maxConcurrentTasks = 1;
      dm.dio = FakeDio(
        ({
          required urlPath,
          required savePath,
          onReceiveProgress,
          cancelToken,
        }) async {
          throw DioException(
            requestOptions: RequestOptions(path: urlPath),
            error: 'synthetic failure',
          );
        },
      );

      final uncaught = <Object>[];

      await runZonedGuarded(() async {
        await dm.addDownload('https://example.com/error.bin', tempDir.path);
        await Future<void>.delayed(const Duration(milliseconds: 800));
      }, (error, stackTrace) {
        uncaught.add(error);
      });

      expect(uncaught, isEmpty);
    });
  });
}
