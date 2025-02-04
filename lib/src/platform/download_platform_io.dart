import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:flutter_download_manager/src/platform/download_platform_interface.dart';

class IODownloadPlatform implements DownloadPlatformInterface {
  IODownloadPlatform(this.dio);
  final Dio dio;

  static const partialExtension = '.partial';
  static const tempExtension = '.temp';

  @override
  Future<DownloadTask?> addDownload(String url, String localPath) async {
    if (url.isEmpty) return null;

    final savedDir = localPath.isEmpty ? '.' : localPath;
    final isDirectory = Directory(savedDir).existsSync();
    final downloadFilename = isDirectory
        ? savedDir + Platform.pathSeparator + getFileNameFromUrl(url)
        : savedDir;

    return DownloadTask(DownloadRequest(url, downloadFilename));
  }

  @override
  Future<void> download({
    required String url,
    required String savePath,
    CancelToken? cancelToken,
    bool forceDownload = false,
  }) async {
    late String partialFilePath;
    late File partialFile;

    debugPrint('download: $url');
    partialFilePath = '$savePath$partialExtension';
    partialFile = File(partialFilePath);

    try {
      final partialFileExist = partialFile.existsSync();

      if (partialFileExist) {
        if (kDebugMode) {
          debugPrint('Partial File Exists');
        }

        final partialFileLength = await partialFile.length();

        final response = await dio.download(
          url,
          partialFilePath + tempExtension,
          onReceiveProgress: (received, total) {
            // Progress handling can be implemented if needed
          },
          options: Options(
            headers: {HttpHeaders.rangeHeader: 'bytes=$partialFileLength-'},
          ),
          cancelToken: cancelToken,
        );

        if (response.statusCode == HttpStatus.partialContent) {
          final ioSink = partialFile.openWrite(mode: FileMode.writeOnlyAppend);
          final tempFile = File(partialFilePath + tempExtension);
          await ioSink.addStream(tempFile.openRead());
          await tempFile.delete();
          await ioSink.close();
          await partialFile.rename(savePath);
        }
      } else {
        final response = await dio.download(
          url,
          partialFilePath,
          onReceiveProgress: (received, total) {
            // Progress handling can be implemented if needed
          },
          cancelToken: cancelToken,
          deleteOnError: false,
        );

        if (response.statusCode == HttpStatus.ok) {
          await partialFile.rename(savePath);
        }
      }
    } catch (e) {
      if (cancelToken?.isCancelled ?? false) {
        // Handle cancellation
        if (partialFile.existsSync()) {
          final tempFile = File(partialFilePath + tempExtension);
          if (tempFile.existsSync()) {
            final ioSink =
                partialFile.openWrite(mode: FileMode.writeOnlyAppend);
            await ioSink.addStream(tempFile.openRead());
            await ioSink.close();
            await tempFile.delete();
          }
        }
      } else {
        // Handle other errors
        rethrow;
      }
    }
  }

  @override
  String getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : url;
    } catch (e) {
      return url;
    }
  }
}
