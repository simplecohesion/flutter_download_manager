// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'package:file_system_access_api/file_system_access_api.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';

class OpfsHelper {
  static Future<FileSystemDirectoryHandle?> getDirectoryHandle({
    String? localPath,
  }) async {
    final directoryHandle = await html.window.navigator.storage?.getDirectory();
    if (directoryHandle == null) {
      throw UnsupportedError('File System Access API is not supported.');
    }
    if (localPath != null) {
      return directoryHandle.getDirectoryHandle(localPath);
    }
    return directoryHandle;
  }

  static Future<FileSystemFileHandle?> getFileHandle(String localPath) async {
    final parts = localPath.split(Platform.pathSeparator);

    final directoryPath =
        parts.take(parts.length - 1).join(Platform.pathSeparator);
    final fileName = parts.last;
    // final fileName = parts.last;
    // final directoryName = parts.length > 1 ? parts.first : null;

    final directoryHandle = await getDirectoryHandle(localPath: directoryPath);
    if (directoryHandle == null) {
      return null;
    }
    return directoryHandle.getFileHandle(fileName, create: true);
  }

  static Future<String?> getPathToLocalFile(String filename) async {
    try {
      final rootDirectoryHandle = await getDirectoryHandle();
      if (rootDirectoryHandle == null) {
        throw UnsupportedError('File System Access API is not supported.');
      }

      final fileHandle = await rootDirectoryHandle.getFileHandle(filename);
      final file = await fileHandle.getFile();

      final fileUrl = html.Url.createObjectUrlFromBlob(file);
      debugPrint('File URL: $fileUrl');

      return fileUrl;
    } catch (e) {
      debugPrint('Error reading file from OPFS: $e');
      return null;
    }
  }

  static Future<void> writeFile(Uint8List data, String filename) async {
    try {
      final directoryHandle =
          await html.window.navigator.storage?.getDirectory();
      if (directoryHandle != null) {
        final fileHandle =
            await directoryHandle.getFileHandle(filename, create: true);
        final writable = await fileHandle.createWritable();

        // Write the data to the file
        await writable.writeAsArrayBuffer(data);
        await writable.close();
      } else {
        throw UnsupportedError('File System Access API is not supported.');
      }
    } catch (e) {
      debugPrint('Error in writeFile: $e');
      rethrow;
    }
  }
}

/// This is a bridge to interact with the web's OPFS writable stream via JavaScript interop.
///
// @JS()
// @staticInterop
// class FileSystemWritableFileStream {}

// extension FileSystemWritableFileStreamExtension
//     on FileSystemWritableFileStream {
//   external JSPromise write(JSAny data);
//   external JSPromise close();
// }
