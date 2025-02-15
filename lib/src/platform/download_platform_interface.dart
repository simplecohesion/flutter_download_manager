import 'package:dio/dio.dart';

/// An abstract interface for implementing platform-specific download functionality.
///
/// This interface defines the contract for handling file operations across different
/// platforms (web, mobile, desktop). Implementations should handle platform-specific
/// details while maintaining consistent behavior.
abstract class DownloadPlatformInterface {
  /// Downloads a file from the specified URL and saves it to the given path.
  ///
  /// Parameters:
  /// - [url]: The URL of the file to download
  /// - [savePath]: The local path where the file should be saved
  /// - [cancelToken]: Optional token to cancel the download operation
  /// - [forceDownload]: If true, will re-download even if the file exists
  ///
  /// Throws a platform-specific exception if the download fails.
  Future<void> download({
    required String url,
    required String savePath,
    CancelToken? cancelToken,
    bool forceDownload = false,
  });

  /// Deletes a file at the specified path.
  ///
  /// Parameters:
  /// - [path]: The path to the file that should be deleted
  ///
  /// Throws a platform-specific exception if the file cannot be deleted
  /// or does not exist.
  Future<void> deleteFile(String path);

  /// Creates a directory at the specified path.
  ///
  /// Parameters:
  /// - [path]: The path where the directory should be created
  ///
  /// Throws a platform-specific exception if the directory cannot be created
  /// or already exists.
  Future<void> createDirectory(String path);

  /// Deletes a directory and all its contents at the specified path.
  ///
  /// Parameters:
  /// - [path]: The path to the directory that should be deleted
  ///
  /// Throws a platform-specific exception if the directory cannot be deleted
  /// or does not exist.
  Future<void> deleteDirectory(String path);

  /// Retrieves a list of file paths in the specified directory.
  ///
  /// Parameters:
  /// - [path]: The path to the directory to list files from
  ///
  /// Returns a list of absolute paths to the files in the directory.
  /// The list will be empty if the directory is empty or does not exist.
  Future<List<String>> getFilesInDirectory(String path);

  /// Retrieves a list of subdirectory paths in the specified directory.
  ///
  /// Parameters:
  /// - [path]: The path to the directory to list subdirectories from
  ///
  /// Returns a list of absolute paths to the subdirectories in the directory.
  /// The list will be empty if there are no subdirectories or the directory
  /// does not exist.
  Future<List<String>> getDirectoriesInDirectory(String path);
}
