// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'package:file_system_access_api/file_system_access_api.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';

/// A helper class for interacting with the Origin Private File System (OPFS) in web browsers.
///
/// OPFS is a web-specific storage mechanism that provides a sandboxed file system
/// for web applications. This class provides utility methods to handle file operations
/// within this file system.
class OpfsHelper {
  /// Retrieves the root directory handle of the Origin Private File System.
  ///
  /// Throws [UnsupportedError] if the File System Access API is not supported
  /// by the browser.
  ///
  /// Returns a [FileSystemDirectoryHandle] representing the root directory.
  static Future<FileSystemDirectoryHandle> getRootDirectoryHandle() async {
    final directoryHandle = await html.window.navigator.storage?.getDirectory();
    if (directoryHandle == null) {
      throw UnsupportedError('File System Access API is not supported.');
    }
    return directoryHandle;
  }

  /// Gets a directory handle for the specified path.
  ///
  /// [path] The path to the directory.
  /// [create] If true, creates the directory if it doesn't exist.
  ///
  /// Returns a [FileSystemDirectoryHandle] for the specified directory.
  static Future<FileSystemDirectoryHandle> getDirectoryHandle(
    String path, {
    bool create = false,
  }) async {
    final rootHandle = await getRootDirectoryHandle();
    return rootHandle.getDirectoryHandle(path, create: create);
  }

  /// Gets a file handle for the specified path.
  ///
  /// [path] The full path to the file, including directories.
  ///
  /// Returns a [FileSystemFileHandle] for the specified file.
  /// The file will be created if it doesn't exist.
  static Future<FileSystemFileHandle?> getFileHandle(String path) async {
    final parts = path.split(Platform.pathSeparator);

    final directoryPath =
        parts.take(parts.length - 1).join(Platform.pathSeparator);
    final fileName = parts.last;

    final directoryHandle = await getDirectoryHandle(directoryPath);

    return directoryHandle.getFileHandle(fileName, create: true);
  }

  /// Retrieves a local URL for accessing a file in the OPFS.
  ///
  /// [filename] The name of the file to access.
  ///
  /// Returns a URL string that can be used to access the file, or null if the
  /// file cannot be accessed.
  static Future<String?> getPathToLocalFile(String filename) async {
    try {
      final rootDirectoryHandle = await getRootDirectoryHandle();

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

  /// Writes binary data to a file in the OPFS.
  ///
  /// [data] The binary data to write as a [Uint8List].
  /// [filename] The name of the file to write to.
  ///
  /// Throws [UnsupportedError] if the File System Access API is not supported.
  /// Rethrows any errors that occur during the write operation.
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
