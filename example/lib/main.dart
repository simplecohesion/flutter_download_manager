// ignore_for_file: cascade_invocations

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';

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
  String url2 = 'http://download.dcloud.net.cn/HBuilder.9.0.2.macosx_64.dmg';

  String url3 =
      'https://cdn.jsdelivr.net/gh/flutterchina/flutter-in-action@1.0/docs/imgs/book.jpg';
  String url = 'http://app01.78x56.com/Xii_2021-03-13%2010%EF%BC%9A41.ipa';
  String url4 =
      'https://jsoncompare.org/LearningContainer/SampleFiles/Video/MP4/sample-mp4-file.mp4';
  String url5 =
      'https://jsoncompare.org/LearningContainer/SampleFiles/Video/MP4/Sample-Video-File-For-Testing.mp4';

  DownloadManager downloadManager = DownloadManager.instance;
  String savedDir = '';

  @override
  void initState() {
    super.initState();
    getApplicationSupportDirectory().then((value) => savedDir = value.path);
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
                    }
                  } else {
                    downloadManager.addDownload(
                      url,
                      '$savedDir/${downloadManager.getFileNameFromUrl(url)}',
                    );
                  }
                });
              },
              onDelete: (url) {
                final fileName =
                    '$savedDir/${downloadManager.getFileNameFromUrl(url)}';
                final file = File(fileName);
                file.delete();

                downloadManager.removeDownload(url);
                setState(() {});
              },
              url: url,
              downloadTask: downloadManager.getDownload(url),
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
                    }
                  } else {
                    downloadManager.addDownload(
                      url,
                      '$savedDir/${downloadManager.getFileNameFromUrl(url)}',
                    );
                  }
                });
              },
              onDelete: (url) {
                final fileName =
                    '$savedDir/${downloadManager.getFileNameFromUrl(url)}';
                final file = File(fileName);
                file.delete();

                downloadManager.removeDownload(url);
                setState(() {});
              },
              url: url2,
              downloadTask: downloadManager.getDownload(url2),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Batch Downloads'),
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
                          }
                        } else {
                          downloadManager.addDownload(
                            url,
                            '$savedDir/${downloadManager.getFileNameFromUrl(url)}',
                          );
                        }
                      });
                    },
                    onDelete: (url) {
                      final fileName =
                          '$savedDir/${downloadManager.getFileNameFromUrl(url)}';
                      final file = File(fileName);
                      file.delete();

                      downloadManager.removeDownload(url);
                      setState(() {});
                    },
                    url: url3,
                    downloadTask: downloadManager.getDownload(url3),
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
                          }
                        } else {
                          downloadManager.addDownload(
                            url,
                            '$savedDir/${downloadManager.getFileNameFromUrl(url)}',
                          );
                        }
                      });
                    },
                    onDelete: (url) {
                      final fileName =
                          '$savedDir/${downloadManager.getFileNameFromUrl(url)}';
                      final file = File(fileName);
                      file.delete();

                      downloadManager.removeDownload(url);
                      setState(() {});
                    },
                    url: url4,
                    downloadTask: downloadManager.getDownload(url4),
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
                          }
                        } else {
                          downloadManager.addDownload(
                            url,
                            '$savedDir/${downloadManager.getFileNameFromUrl(url)}',
                          );
                        }
                      });
                    },
                    onDelete: (url) {
                      final fileName =
                          '$savedDir/${downloadManager.getFileNameFromUrl(url)}';
                      final file = File(fileName);
                      file.delete();

                      downloadManager.removeDownload(url);
                      setState(() {});
                    },
                    url: url5,
                    downloadTask: downloadManager.getDownload(url5),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          downloadManager.addBatchDownloads(
                            [url3, url4, url5],
                            savedDir,
                          );
                          setState(() {});
                        },
                        child: const Text('Download All'),
                      ),
                      TextButton(
                        onPressed: () {
                          downloadManager.pauseDownloads([url3, url4, url5]);
                        },
                        child: const Text('Pause All'),
                      ),
                      TextButton(
                        onPressed: () {
                          downloadManager.cancelDownloads([url3, url4, url5]);
                        },
                        child: const Text('Cancel All'),
                      ),
                    ],
                  ),
                  ValueListenableBuilder(
                    valueListenable: downloadManager
                        .getDownloadsProgress([url3, url4, url5]),
                    builder: (context, value, child) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: LinearProgressIndicator(
                          value: value,
                        ),
                      );
                    },
                  ),
                  FutureBuilder<List<DownloadTask?>?>(
                    future: downloadManager
                        .whenDownloadsComplete([url3, url4, url5]),
                    builder: (
                      BuildContext context,
                      AsyncSnapshot<List<DownloadTask?>?> snapshot,
                    ) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                          return const Text(
                            'I will wait till the batch downloads have been completed',
                          );
                        default:
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            return snapshot.data != null
                                ? Column(
                                    children: [
                                      const Text('Result'),
                                      for (final e in snapshot.data!)
                                        e != null
                                            ? Padding(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Text(
                                                  '${downloadManager.getFileNameFromUrl(e.request.url)}: ${e.status.value}',
                                                ),
                                              )
                                            : const Text('Not found'),
                                    ],
                                  )
                                : const Text('No Downloads have been found');
                          }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListItem extends StatelessWidget {
  final Function(String) onDownloadPlayPausedPressed;
  final Function(String) onDelete;
  DownloadTask? downloadTask;
  String url = '';

  ListItem({
    required this.url,
    required this.onDownloadPlayPausedPressed,
    required this.onDelete,
    Key? key,
    this.downloadTask,
  }) : super(key: key);

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
