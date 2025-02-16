import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:tester/views/download_view.dart';
import 'package:tester/views/file_system_view.dart';
import 'package:tester/views/file_view.dart';

class RootView extends StatelessWidget {
  const RootView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text('Flutter download manager test'),
          subtitle: const Text('A simple counter app'),
          leading: [
            GhostButton(
              onPressed: () {
                openDrawer(
                  context: context,
                  builder: (context) {
                    return Container(
                      alignment: Alignment.center,
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: const Text('Drawer'),
                    );
                  },
                  position: OverlayPosition.left,
                );
              },
              density: ButtonDensity.icon,
              child: const Icon(Icons.menu),
            ),
          ],
          trailing: [
            GhostButton(
              density: ButtonDensity.icon,
              onPressed: () {
                openSheet(
                  context: context,
                  builder: (context) {
                    return Container(
                      alignment: Alignment.center,
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: const Text('Sheet'),
                    );
                  },
                  position: OverlayPosition.right,
                );
              },
              child: const Icon(Icons.search),
            ),
          ],
        ),
        const Divider(),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(child: const DownloadView()),
          Flexible(child: const FileSystemView()),
          Flexible(child: const FileView()),
        ],
      ).separator(const Gap(8)).withPadding(all: 8),
    );
  }
}
