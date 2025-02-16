// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';
import 'package:web/web.dart';

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
    final directoryHandle =
        await window.navigator.storage.getDirectory().toDart;
    return directoryHandle;
  }

  /// Gets a directory handle for the specified path.
  ///
  /// [directoryPath] The path to the directory.
  /// [create] If true, creates the directory if it doesn't exist.
  ///
  /// Returns a [FileSystemDirectoryHandle] for the specified directory.
  static Future<FileSystemDirectoryHandle> getDirectoryHandle(
    String directoryPath, {
    bool create = false,
  }) async {
    final rootHandle = await getRootDirectoryHandle();

    if (directoryPath.isEmpty) {
      return rootHandle;
    }

    final pathParts = directoryPath.split(Platform.pathSeparator);
    if (pathParts.isEmpty) {
      throw ArgumentError('Path cannot be empty');
    }
    // if the first part is a ., remove it as that is the default directory
    if (pathParts.first == '.') {
      pathParts.removeAt(0);
    }

    // if the last part is a .., throw an error as that is not allowed
    if (pathParts.last == '..') {
      throw ArgumentError('Path cannot contain ".."');
    }

    var directoryHandle = rootHandle;

    // loop through the path parts to build up a directory handle, don't use
    //the last part as that is the file name
    for (final part in pathParts) {
      directoryHandle = await directoryHandle
          .getDirectoryHandle(
            part,
            FileSystemGetDirectoryOptions(create: create),
          )
          .toDart;
    }

    return directoryHandle;
  }

  /// Gets a file handle for the specified path.
  ///
  /// [filePath] The full path to the file, including directories.
  ///
  /// Returns a [FileSystemFileHandle] for the specified file.
  /// The file will be created if it doesn't exist.
  static Future<FileSystemFileHandle> getFileHandle(String filePath) async {
    final parts = filePath.split(Platform.pathSeparator);
    if (parts.isEmpty) {
      throw ArgumentError('Path cannot be empty');
    }

    final directoryPath =
        parts.take(parts.length - 1).join(Platform.pathSeparator);
    final fileName = parts.last;

    final directoryHandle = await getDirectoryHandle(directoryPath);

    return directoryHandle
        .getFileHandle(fileName, FileSystemGetFileOptions(create: true))
        .toDart;
  }

  static Future<void> deleteFile(String filePath) async {
    final pathParts = filePath.split(Platform.pathSeparator);
    if (pathParts.isEmpty) {
      throw ArgumentError('Path cannot be empty');
    }

    final fileName = pathParts.last;

    final parentDirectoryHandle = await _getParentDirectoryHandle(filePath);
    await parentDirectoryHandle.removeEntry(fileName).toDart;
  }

  static Future<void> deleteDirectory(String directoryPath) async {
    final pathParts = directoryPath.split(Platform.pathSeparator);
    if (pathParts.isEmpty) {
      throw ArgumentError('Path cannot be empty');
    }

    final directoryName = pathParts.last;

    final parentDirectoryHandle =
        await _getParentDirectoryHandle(directoryPath);
    await parentDirectoryHandle
        .removeEntry(directoryName, FileSystemRemoveOptions(recursive: true))
        .toDart;
  }

  static Future<FileSystemDirectoryHandle> _getParentDirectoryHandle(
    String path,
  ) async {
    final pathParts = path.split(Platform.pathSeparator);

    if (pathParts.isEmpty) {
      throw ArgumentError('Path cannot be empty');
    }

    if (pathParts.length == 1) {
      return getRootDirectoryHandle();
    }

    final parentDirectoryPath =
        pathParts.take(pathParts.length - 1).join(Platform.pathSeparator);

    return getDirectoryHandle(parentDirectoryPath);
  }

  /// Retrieves a local URL for accessing a file in the OPFS.
  ///
  /// [filename] The name of the file to access.
  ///
  /// Returns a URL string that can be used to access the file, or null if the
  /// file cannot be accessed.
  static Future<String?> getPathToLocalFile(String filename) async {
    try {
      final fileHandle = await getFileHandle(filename);

      final file = await fileHandle.getFile().toDart;

      final fileUrl = URL.createObjectURL(file);
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
  // static Future<void> writeFile(Uint8List data, String filename) async {
  //   try {
  //     final fileHandle = await getFileHandle(filename);
  //     final writable = await fileHandle.createWritable().toDart;

  //     // Write the data to the file
  //     await writable.getWriter().write(data.toJS).toDart;
  //     await writable.close().toDart;
  //   } catch (e) {
  //     debugPrint('Error in writeFile: $e');
  //     rethrow;
  //   }
  // }
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
