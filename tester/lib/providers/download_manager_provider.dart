import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'download_manager_provider.g.dart';

@riverpod
DownloadManager downloadManager(Ref ref) {
  return DownloadManager.instance;
}
