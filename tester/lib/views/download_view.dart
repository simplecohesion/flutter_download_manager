import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:tester/providers/download_logs_provider.dart';

class DownloadView extends HookConsumerWidget {
  const DownloadView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urls = [
      'https://www.sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
      'https://www.sample-videos.com/img/Sample-jpg-image-1mb.jpg',
      'https://www.sample-videos.com/zip/10mb.zip',
    ];

    final pathController = useTextEditingController();

    return OutlinedContainer(
        child: Column(
      children: [
        Text('Downloads'),
        TextField(
          controller: pathController,
        ),
        Expanded(
          child: ListView.builder(
            itemCount: urls.length,
            itemBuilder: (context, index) {
              return GhostButton(
                onPressed: () {
                  ref
                      .read(downloadLogsProvider.notifier)
                      .addDownload(urls[index], pathController.text);
                },
                alignment: Alignment.centerLeft,
                child: Text(urls[index]),
              );
            },
          ),
        ),
        SizedBox(
            height: 300,
            child: Card(
              child: Consumer(
                builder: (context, ref, child) {
                  return Text(
                    ref.watch(downloadLogsProvider),
                    maxLines: 50,
                    textAlign: TextAlign.left,
                  );
                },
              ),
            ))
      ],
    ));
  }
}
