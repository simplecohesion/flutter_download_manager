import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:tester/models/file_system_item.dart';

part 'file_systems_items_provider.g.dart';

@riverpod
class FileSystemItems extends _$FileSystemItems {
  @override
  List<TreeNode<FileSystemItem>>? build() {
    return [];
  }

  Future<void> refresh() async {
    state = null;
    try {
      final storageItems = await _getDirectories('');
      state = storageItems;
    } catch (e) {
      state = [];
      rethrow;
    }
  }

  Future<List<TreeNode<FileSystemItem>>> _getDirectories(
    String directoryPath,
  ) async {
    final downloadManager = DownloadManager.instance;

    final items = <TreeNode<FileSystemItem>>[];

    final directories = await downloadManager.getDirectoriesInDirectory(
      directoryPath,
    );

    for (final directory in directories) {
      final children = await _getDirectories('$directoryPath/$directory');
      items.add(
        TreeItem(
          data: FileSystemFolder(
            name: directory,
            path: '$directoryPath/$directory',
          ),
          children: children,
        ),
      );
    }

    final files = await downloadManager.getFilesInDirectory(directoryPath);

    for (final file in files) {
      items.add(
        TreeItem(
          data: FileSystemFile(
            name: file,
            path: '$directoryPath/$file',
            type: 'file',
          ),
        ),
      );
    }

    return items;
  }

  void setUiState(List<TreeNode<FileSystemItem>> items) {
    state = items;
  }
}
