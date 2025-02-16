// ignore_for_file: cascade_invocations, public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:universal_io/io.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({required this.title, super.key});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final url1 =
      'https://www.sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4';
  final url2 = 'https://www.sample-videos.com/img/Sample-jpg-image-1mb.jpg';
  final url3 = 'https://www.sample-videos.com/zip/10mb.zip';

  DownloadManager downloadManager = DownloadManager.instance;
  final directoryPath =
      '.${Platform.pathSeparator}test${Platform.pathSeparator}downloads';

  @override
  void initState() {
    super.initState();
    // Create directory if it doesn't exist

    downloadManager.createDirectory(directoryPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Download Manager')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListItem(
              onDownloadPlayPausedPressed: (url) async {
                setState(() {
                  final task = downloadManager.getDownload(url);
                  if (task != null && !task.status.value.isCompleted) {
                    switch (task.status.value) {
                      case DownloadStatus.downloading:
                        downloadManager.pauseDownload(url);
                      case DownloadStatus.paused:
                        downloadManager.resumeDownload(url);
                      case DownloadStatus.queued:
                        // Do nothing while queued
                        break;
                      case DownloadStatus.completed:
                        // Already completed, do nothing
                        break;
                      default:
                      // Do nothing for other cases
                    }
                  } else {
                    final fileName = url.split('/').last;
                    downloadManager.addDownload(
                      url,
                      '$directoryPath${Platform.pathSeparator}$fileName',
                    );
                  }
                });
              },
              onDelete: (url) async {
                final fileName = url.split('/').last;
                await downloadManager.deleteFile(
                  '$directoryPath${Platform.pathSeparator}$fileName',
                );
                await downloadManager.removeDownload(url);
                setState(() {});
              },
              url: url1,
              downloadTask: downloadManager.getDownload(url1),
            ),
            ListItem(
              onDownloadPlayPausedPressed: (url) async {
                setState(() {
                  final task = downloadManager.getDownload(url);

                  if (task != null && !task.status.value.isCompleted) {
                    switch (task.status.value) {
                      case DownloadStatus.downloading:
                        downloadManager.pauseDownload(url);
                      case DownloadStatus.paused:
                        downloadManager.resumeDownload(url);
                      case DownloadStatus.queued:
                      // Do nothing while queued
                      case DownloadStatus.completed:
                        // Already completed, do nothing
                        break;
                      default:
                      // Do nothing for other cases
                    }
                  } else {
                    final fileName = url.split('/').last;
                    downloadManager.addDownload(
                      url,
                      '$directoryPath${Platform.pathSeparator}$fileName',
                    );
                  }
                });
              },
              onDelete: (url) async {
                final fileName = url.split('/').last;
                await downloadManager.deleteFile(
                  '$directoryPath${Platform.pathSeparator}$fileName',
                );
                await downloadManager.removeDownload(url);
                setState(() {});
              },
              url: url2,
              downloadTask: downloadManager.getDownload(url2),
            ),
            // Padding(
            //   padding: const EdgeInsets.all(8),
            //   child: Column(
            //     children: [
            //       const Padding(
            //         padding: EdgeInsets.all(8),
            //         child: Text('Batch Downloads'),
            //       ),
            //       ListItem(
            //         onDownloadPlayPausedPressed: (url) async {
            //           setState(() {
            //             final task = downloadManager.getDownload(url);

            //             if (task != null && !task.status.value.isCompleted) {
            //               switch (task.status.value) {
            //                 case DownloadStatus.downloading:
            //                   downloadManager.pauseDownload(url);
            //                 case DownloadStatus.paused:
            //                   downloadManager.resumeDownload(url);
            //                 case DownloadStatus.queued:
            //                   // Do nothing while queued
            //                   break;
            //                 case DownloadStatus.completed:
            //                   // Already completed, do nothing
            //                   break;
            //                 default:
            //                 // Do nothing for other cases
            //               }
            //             } else {
            //               final fileName = url.split('/').last;
            //               downloadManager.addDownload(
            //                 url,
            //                 '${directory1.path}${Platform.pathSeparator}$fileName',
            //               );
            //             }
            //           });
            //         },
            //         onDelete: (url) {
            //           final fileName = url.split('/').last;
            //           final file = File(
            //             '${directory1.path}${Platform.pathSeparator}$fileName',
            //           );
            //           file.delete();

            //           downloadManager.removeDownload(url);
            //           setState(() {});
            //         },
            //         url: url3,
            //         downloadTask: downloadManager.getDownload(url3),
            //       ),
            //       Row(
            //         mainAxisAlignment: MainAxisAlignment.center,
            //         children: [
            //           TextButton(
            //             onPressed: () async {
            //               for (final downloadUrl in [url1, url2, url3]) {
            //                 final fileName = downloadUrl.split('/').last;
            //                 await downloadManager.addDownload(
            //                   downloadUrl,
            //                   '${directory1.path}${Platform.pathSeparator}$fileName',
            //                 );
            //               }
            //               setState(() {});
            //             },
            //             child: const Text('Download All'),
            //           ),
            //           TextButton(
            //             onPressed: () {
            //               downloadManager.pauseDownloads([url1, url2, url3]);
            //             },
            //             child: const Text('Pause All'),
            //           ),
            //           TextButton(
            //             onPressed: () {
            //               downloadManager.cancelDownloads([url1, url2, url3]);
            //             },
            //             child: const Text('Cancel All'),
            //           ),
            //         ],
            //       ),
            //       ValueListenableBuilder(
            //         valueListenable: downloadManager
            //             .getDownloadsProgress([url1, url2, url3]),
            //         builder: (context, value, child) {
            //           return Container(
            //             margin: const EdgeInsets.symmetric(vertical: 4),
            //             child: LinearProgressIndicator(
            //               value: value,
            //             ),
            //           );
            //         },
            //       ),
            //       FutureBuilder<List<DownloadTask?>?>(
            //         future: downloadManager
            //             .whenDownloadsComplete([url1, url2, url3]),
            //         builder: (
            //           BuildContext context,
            //           AsyncSnapshot<List<DownloadTask?>?> snapshot,
            //         ) {
            //           switch (snapshot.connectionState) {
            //             case ConnectionState.waiting:
            //               return const Text(
            //                 'I will wait till the batch downloads have been completed',
            //               );
            //             default:
            //               if (snapshot.hasError) {
            //                 return Text('Error: ${snapshot.error}');
            //               } else {
            //                 return snapshot.data != null
            //                     ? Column(
            //                         children: [
            //                           const Text('Result'),
            //                           for (final e in snapshot.data!)
            //                             e != null
            //                                 ? Padding(
            //                                     padding:
            //                                         const EdgeInsets.all(8),
            //                                     child: Text(
            //                                       '${e.request.url.split('/').last}: ${e.status.value}',
            //                                     ),
            //                                   )
            //                                 : const Text('Not found'),
            //                         ],
            //                       )
            //                     : const Text('No Downloads have been found');
            //               }
            //           }
            //         },
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class ListItem extends StatelessWidget {
  const ListItem({
    required this.url,
    required this.onDownloadPlayPausedPressed,
    required this.onDelete,
    super.key,
    this.downloadTask,
  });
  final Future<void> Function(String) onDownloadPlayPausedPressed;
  final Future<void> Function(String) onDelete;

  final DownloadTask? downloadTask;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.amber,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        url,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (downloadTask != null)
                        ValueListenableBuilder(
                          valueListenable: downloadTask!.status,
                          builder: (context, value, child) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                '$value',
                                style: const TextStyle(fontSize: 16),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                if (downloadTask != null)
                  ValueListenableBuilder(
                    valueListenable: downloadTask!.status,
                    builder: (context, value, child) {
                      switch (downloadTask!.status.value) {
                        case DownloadStatus.downloading:
                          return IconButton(
                            onPressed: () {
                              onDownloadPlayPausedPressed(url);
                            },
                            icon: const Icon(Icons.pause),
                          );
                        case DownloadStatus.paused:
                          return IconButton(
                            onPressed: () {
                              onDownloadPlayPausedPressed(url);
                            },
                            icon: const Icon(Icons.play_arrow),
                          );
                        case DownloadStatus.completed:
                          return IconButton(
                            onPressed: () {
                              onDelete(url);
                            },
                            icon: const Icon(Icons.delete),
                          );
                        case DownloadStatus.failed:
                        case DownloadStatus.canceled:
                          return IconButton(
                            onPressed: () {
                              onDownloadPlayPausedPressed(url);
                            },
                            icon: const Icon(Icons.download),
                          );
                        case DownloadStatus.queued:
                          return Text(
                            '$value',
                            style: const TextStyle(fontSize: 16),
                          );
                      }
                    },
                  )
                else
                  IconButton(
                    onPressed: () {
                      onDownloadPlayPausedPressed(url);
                    },
                    icon: const Icon(Icons.download),
                  ),
              ],
            ), // if (widget.item.isDownloadingOrPaused)
            if (downloadTask != null && !downloadTask!.status.value.isCompleted)
              ValueListenableBuilder(
                valueListenable: downloadTask!.progress,
                builder: (context, value, child) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: LinearProgressIndicator(
                      value: value,
                      color: downloadTask!.status.value == DownloadStatus.paused
                          ? Colors.grey
                          : Colors.amber,
                    ),
                  );
                },
              ),
            if (downloadTask != null)
              FutureBuilder<DownloadStatus>(
                future: downloadTask!.whenDownloadComplete(),
                builder: (
                  BuildContext context,
                  AsyncSnapshot<DownloadStatus> snapshot,
                ) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return const Text(
                        'I will wait till this download has been completed',
                      );
                    default:
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        return Text('Result: ${snapshot.data}');
                      }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
