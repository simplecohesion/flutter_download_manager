import 'package:shadcn_flutter/shadcn_flutter.dart';

@immutable
class FileSystemItem {
  final String name;
  final String path;

  const FileSystemItem({required this.name, required this.path});
}

@immutable
class FileSystemFile extends FileSystemItem {
  final String? type;
  final int? size;
  final DateTime? createdAt;

  const FileSystemFile({
    required super.name,
    required super.path,
    this.type,
    this.size,
    this.createdAt,
  });
}

@immutable
class FileSystemFolder extends FileSystemItem {
  const FileSystemFolder({required super.name, required super.path});
}
