import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:path_provider/path_provider.dart';

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
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var url2 = "http://download.dcloud.net.cn/HBuilder.9.0.2.macosx_64.dmg";

  var url3 =
      'https://cdn.jsdelivr.net/gh/flutterchina/flutter-in-action@1.0/docs/imgs/book.jpg';
  var url = "http://app01.78x56.com/Xii_2021-03-13%2010%EF%BC%9A41.ipa";
  var url4 =
      "https://jsoncompare.org/LearningContainer/SampleFiles/Video/MP4/sample-mp4-file.mp4";
  var url5 =
      "https://jsoncompare.org/LearningContainer/SampleFiles/Video/MP4/Sample-Video-File-For-Testing.mp4";

  final downloadManager = DownloadManager();
  String savedDir = "";
  bool isStorageReady = false;

  @override
  void initState() {
    super.initState();
    _initSavedDir();
  }

  Future<void> _initSavedDir() async {
    try {
      final dir = await getApplicationSupportDirectory();
      if (!mounted) return;
      setState(() {
        savedDir = dir.path;
        isStorageReady = true;
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to initialize app directory: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onDownloadPlayPausedPressed(String url) async {
    if (!isStorageReady) {
      _showMessage('Preparing storage location. Please wait.');
      return;
    }

    try {
      var task = downloadManager.getDownload(url);

      if (task != null && !task.status.value.isCompleted) {
        switch (task.status.value) {
          case DownloadStatus.queued:
          case DownloadStatus.downloading:
            await downloadManager.pauseDownload(url);
            break;
          case DownloadStatus.paused:
            await downloadManager.resumeDownload(url);
            break;
          case DownloadStatus.completed:
          case DownloadStatus.failed:
          case DownloadStatus.canceled:
            await downloadManager.addDownload(
                url, "$savedDir/${downloadManager.getFileNameFromUrl(url)}");
            break;
        }
      } else {
        await downloadManager.addDownload(
            url, "$savedDir/${downloadManager.getFileNameFromUrl(url)}");
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _showMessage('Download action failed: $e');
    }
  }

  Future<void> _onDelete(String url) async {
    if (!isStorageReady) {
      _showMessage('Storage not ready yet.');
      return;
    }

    try {
      var fileName = "$savedDir/${downloadManager.getFileNameFromUrl(url)}";
      var file = File(fileName);
      if (await file.exists()) {
        await file.delete();
      }
      await downloadManager.removeDownload(url);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _showMessage('Delete failed: $e');
    }
  }

  Future<void> _downloadAll() async {
    if (!isStorageReady) {
      _showMessage('Preparing storage location. Please wait.');
      return;
    }
    try {
      await downloadManager.addBatchDownloads([url3, url4, url5], savedDir);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _showMessage('Batch download failed: $e');
    }
  }

  Future<void> _pauseAll() async {
    await downloadManager.pauseBatchDownloads([url3, url4, url5]);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _cancelAll() async {
    await downloadManager.cancelBatchDownloads([url3, url4, url5]);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Flutter Download Manager")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (!isStorageReady)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Initializing storage directory...'),
              ),
            ListItem(
                enabled: isStorageReady,
                onDownloadPlayPausedPressed: _onDownloadPlayPausedPressed,
                onDelete: _onDelete,
                url: url,
                downloadTask: downloadManager.getDownload(url)),
            ListItem(
                enabled: isStorageReady,
                onDownloadPlayPausedPressed: _onDownloadPlayPausedPressed,
                onDelete: _onDelete,
                url: url2,
                downloadTask: downloadManager.getDownload(url2)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Batch Downloads"),
                  ),
                  ListItem(
                      enabled: isStorageReady,
                      onDownloadPlayPausedPressed: _onDownloadPlayPausedPressed,
                      onDelete: _onDelete,
                      url: url3,
                      downloadTask: downloadManager.getDownload(url3)),
                  ListItem(
                      enabled: isStorageReady,
                      onDownloadPlayPausedPressed: _onDownloadPlayPausedPressed,
                      onDelete: _onDelete,
                      url: url4,
                      downloadTask: downloadManager.getDownload(url4)),
                  ListItem(
                      enabled: isStorageReady,
                      onDownloadPlayPausedPressed: _onDownloadPlayPausedPressed,
                      onDelete: _onDelete,
                      url: url5,
                      downloadTask: downloadManager.getDownload(url5)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                          onPressed: isStorageReady
                              ? () async {
                                  await _downloadAll();
                                }
                              : null,
                          child: Text("Download All")),
                      TextButton(
                          onPressed: isStorageReady
                              ? () async {
                                  await _pauseAll();
                                }
                              : null,
                          child: Text("Pause All")),
                      TextButton(
                          onPressed: isStorageReady
                              ? () async {
                                  await _cancelAll();
                                }
                              : null,
                          child: Text("Cancel All")),
                    ],
                  ),
                  ValueListenableBuilder(
                      valueListenable: downloadManager
                          .getBatchDownloadProgress([url3, url4, url5]),
                      builder: (context, value, child) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: LinearProgressIndicator(
                            value: value,
                          ),
                        );
                      }),
                  FutureBuilder<List<DownloadTask?>?>(
                      future: downloadManager
                          .whenBatchDownloadsComplete([url3, url4, url5]),
                      builder: (BuildContext context,
                          AsyncSnapshot<List<DownloadTask?>?> snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                            return Text(
                                'I will wait till the batch downloads have been completed');
                          default:
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else {
                              return snapshot.data != null
                                  ? Column(children: [
                                      Text("Result"),
                                      for (var e in snapshot.data!)
                                        e != null
                                            ? Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                    "${downloadManager.getFileNameFromUrl(e.request.url)}: ${e.status.value}"),
                                              )
                                            : Text("Not found"),
                                    ])
                                  : Text("No Downloads have been found");
                            }
                        }
                      })
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ListItem extends StatelessWidget {
  final Future<void> Function(String) onDownloadPlayPausedPressed;
  final Future<void> Function(String) onDelete;
  final DownloadTask? downloadTask;
  final String url;
  final bool enabled;

  ListItem(
      {Key? key,
      required this.url,
      required this.onDownloadPlayPausedPressed,
      required this.onDelete,
      this.enabled = true,
      this.downloadTask})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
              color: Colors.amber,
            ),
            borderRadius: BorderRadius.all(Radius.circular(20))),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                              child: Text("$value",
                                  style: TextStyle(fontSize: 16)),
                            );
                          }),
                  ],
                )),
                downloadTask != null
                    ? ValueListenableBuilder(
                        valueListenable: downloadTask!.status,
                        builder: (context, value, child) {
                          switch (downloadTask!.status.value) {
                            case DownloadStatus.queued:
                              return IconButton(
                                  onPressed: enabled
                                      ? () async {
                                          await onDownloadPlayPausedPressed(
                                              url);
                                        }
                                      : null,
                                  icon: const Icon(Icons.pause));
                            case DownloadStatus.downloading:
                              return IconButton(
                                  onPressed: enabled
                                      ? () async {
                                          await onDownloadPlayPausedPressed(
                                              url);
                                        }
                                      : null,
                                  icon: const Icon(Icons.pause));
                            case DownloadStatus.paused:
                              return IconButton(
                                  onPressed: enabled
                                      ? () async {
                                          await onDownloadPlayPausedPressed(
                                              url);
                                        }
                                      : null,
                                  icon: const Icon(Icons.play_arrow));
                            case DownloadStatus.completed:
                              return IconButton(
                                  onPressed: enabled
                                      ? () async {
                                          await onDelete(url);
                                        }
                                      : null,
                                  icon: const Icon(Icons.delete));
                            case DownloadStatus.failed:
                            case DownloadStatus.canceled:
                              return IconButton(
                                  onPressed: enabled
                                      ? () async {
                                          await onDownloadPlayPausedPressed(
                                              url);
                                        }
                                      : null,
                                  icon: const Icon(Icons.download));
                          }
                        })
                    : IconButton(
                        onPressed: enabled
                            ? () async {
                                await onDownloadPlayPausedPressed(url);
                              }
                            : null,
                        icon: const Icon(Icons.download))
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
                        color:
                            downloadTask!.status.value == DownloadStatus.paused
                                ? Colors.grey
                                : Colors.amber,
                      ),
                    );
                  }),
            if (downloadTask != null)
              FutureBuilder<DownloadStatus>(
                  future: downloadTask!.whenDownloadComplete(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DownloadStatus> snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        return Text(
                            'I will wait till this download has been completed');
                      default:
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          return Text('Result: ${snapshot.data}');
                        }
                    }
                  })
          ],
        ),
      ),
    );
  }
}
