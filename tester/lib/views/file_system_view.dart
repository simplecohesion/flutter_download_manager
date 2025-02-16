import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:tester/providers/file_systems_items_provider.dart';

class FileSystemView extends ConsumerWidget {
  const FileSystemView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final treeItems = useState<List<TreeNode<String>>>([
    //   TreeItem(
    //     data: 'Apple',
    //     expanded: true,
    //     children: [
    //       TreeItem(
    //         data: 'Red Apple',
    //         children: [
    //           TreeItem(data: 'Red Apple 1'),
    //           TreeItem(data: 'Red Apple 2'),
    //         ],
    //       ),
    //       TreeItem(data: 'Green Apple'),
    //     ],
    //   ),
    //   TreeItem(
    //     data: 'Banana',
    //     children: [
    //       TreeItem(data: 'Yellow Banana'),
    //       TreeItem(
    //         data: 'Green Banana',
    //         children: [
    //           TreeItem(data: 'Green Banana 1'),
    //           TreeItem(data: 'Green Banana 2'),
    //           TreeItem(data: 'Green Banana 3'),
    //         ],
    //       ),
    //     ],
    //   ),
    //   TreeItem(
    //     data: 'Cherry',
    //     children: [
    //       TreeItem(data: 'Red Cherry'),
    //       TreeItem(data: 'Green Cherry'),
    //     ],
    //   ),
    //   TreeItem(data: 'Date'),
    //   // Tree Root acts as a parent node with no data,
    //   // it will flatten the children into the parent node
    //   TreeRoot(
    //     children: [
    //       TreeItem(
    //         data: 'Elderberry',
    //         children: [
    //           TreeItem(data: 'Black Elderberry'),
    //           TreeItem(data: 'Red Elderberry'),
    //         ],
    //       ),
    //       TreeItem(
    //         data: 'Fig',
    //         children: [
    //           TreeItem(data: 'Green Fig'),
    //           TreeItem(data: 'Purple Fig'),
    //         ],
    //       ),
    //     ],
    //   ),
    // ]);
    final fileSystemItems = ref.watch(fileSystemItemsProvider);

    Future<void> refresh() async {
      try {
        await ref.read(fileSystemItemsProvider.notifier).refresh();
      } catch (e) {
        debugPrint(e.toString());
        if (context.mounted) {
          showToast(
            context: context,
            builder: (context, overlay) => SurfaceCard(
              child: Basic(
                title: const Text('Error'),
                subtitle: Text(e.toString()),
                trailing: PrimaryButton(
                  size: ButtonSize.small,
                  onPressed: () {
                    overlay.close();
                  },
                  child: const Text('Undo'),
                ),
              ),
            ),
            location: ToastLocation.bottomLeft,
          );
        }
      }
    }

    return OutlinedContainer(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          SecondaryButton(
            onPressed: fileSystemItems != null ? () => refresh() : null,
            child: Text('Refresh'),
          ),
          Expanded(
            child: fileSystemItems == null
                ? Center(child: CircularProgressIndicator())
                : fileSystemItems.isEmpty
                    ? Center(child: Text('no items').muted())
                    : TreeView(
                        expandIcon: true,
                        // shrinkWrap: true,
                        recursiveSelection: false,
                        nodes: fileSystemItems,
                        branchLine: BranchLine.path,
                        onSelectionChanged: TreeView.defaultSelectionHandler(
                          fileSystemItems,
                          (value) {
                            ref
                                .read(fileSystemItemsProvider.notifier)
                                .setUiState(value);
                          },
                        ),
                        builder: (context, node) {
                          return TreeItemView(
                            onPressed: () {},
                            trailing: node.leaf
                                ? Container(
                                    width: 16,
                                    height: 16,
                                    alignment: Alignment.center,
                                    child: const CircularProgressIndicator(),
                                  )
                                : null,
                            leading: node.leaf
                                ? const Icon(BootstrapIcons.fileImage)
                                : Icon(
                                    node.expanded
                                        ? BootstrapIcons.folder2Open
                                        : BootstrapIcons.folder2,
                                  ),
                            onExpand: TreeView.defaultItemExpandHandler(
                              fileSystemItems,
                              node,
                              (value) {
                                ref
                                    .read(fileSystemItemsProvider.notifier)
                                    .setUiState(value);
                              },
                            ),
                            child: Text(node.data.name),
                          );
                        },
                      ),
          ),
        ],
      ).separator(const Gap(8)),
    );
  }
}
