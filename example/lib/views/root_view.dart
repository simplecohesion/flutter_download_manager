import 'package:shadcn_flutter/shadcn_flutter.dart';

class RootView extends StatelessWidget {
  const RootView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        headers: [
          AppBar(
            title: const Text('Counter App'),
            subtitle: const Text('A simple counter app'),
            leading: [
              GhostButton(
                onPressed: () {
                  openDrawer(
                    context: context,
                    builder: (context) {
                      return Container(
                        alignment: Alignment.center,
                        constraints: const BoxConstraints(
                          maxWidth: 300,
                        ),
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
                        constraints: const BoxConstraints(
                          maxWidth: 200,
                        ),
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
        // footers: [
        //   const Divider(),
        //   NavigationBar(
        //     onSelected: (i) {
        //       setState(() {
        //         _selected = i;
        //       });
        //     },
        //     index: _selected,
        //     children: [
        //       _buildButton('Home', Icons.home),
        //       _buildButton('Explore', Icons.explore),
        //       _buildButton('Library', Icons.library_music),
        //     ],
        //   ),
        // ],
        child: Row(
          children: [],
        ));
  }
}
