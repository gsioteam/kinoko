
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/models.dart';
import 'package:glib/main/project.dart';
import 'package:kinoko/utils/book_info.dart';
import 'package:kinoko/utils/cached_picture_image.dart';
import 'package:kinoko/utils/plugin/plugin.dart';
import 'package:kinoko/utils/plugins_manager.dart';
import 'package:kinoko/widgets/no_data.dart';
import 'package:path_provider_ex/path_provider_ex.dart';
import '../configs.dart';
import '../main.dart';
import 'picture_viewer.dart';
import '../utils/download_manager.dart';
import '../localizations/localizations.dart';
import '../utils/fullscreen.dart';
import '../utils/neo_cache_manager.dart';
import 'package:filesystem_picker/filesystem_picker.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;
import 'package:path/path.dart' as path;

import '../widgets/instructions_dialog.dart';

class BookData {
  BookInfo bookInfo;

  List<DownloadQueueItem> items = [];

  BookData(this.bookInfo);
}

enum _CellType {
  Book,
  Chapter
}

class CellData {
  _CellType type;
  bool extend = false;
  dynamic data;

  CellData({
    required this.type,
    this.data
  });
}

class ChapterCell extends StatefulWidget {

  final DownloadQueueItem item;
  final VoidCallback? onTap;
  final bool editMode;

  ChapterCell(this.item, {
    key,
    this.onTap,
    this.editMode = false
  }):super(key: key);

  @override
  State<StatefulWidget> createState() => _ChapterCellState();
}

class _ChapterCellState extends State<ChapterCell> {

  Widget extendButtons(BuildContext context, DownloadQueueItem queueItem) {
    if (widget.editMode) {
      return IconButton(
        icon: Icon(Icons.delete_outline),
        onPressed: () {

        },
      );
    } else {
      const double IconSize = 24;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            child: queueItem.state == DownloadState.Complete ?
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () async {

                var status = await Permission.storage.status;
                switch (status) {
                  case PermissionStatus.granted:
                    break;
                  default: {
                    var status = await Permission.storage.request();
                    if (status != PermissionStatus.granted) {
                      Fluttertoast.showToast(
                          msg: kt("no_permission")
                      );
                      return;
                    }
                  }
                }
                var lists = await PathProviderEx.getStorageInfo();
                if (lists.length > 0) {
                  var info = lists.last;
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) {
                        return FilesystemPicker(
                            rootDirectory: Directory(info.rootDir),
                            onSelect: (folderPath) async {
                              // DownloadQueueItem queueItem = widget.item;
                              // DataItem item = queueItem.item.retain();
                              // String name = "${queueItem.info.title}";
                              // if (item.title.isNotEmpty) {
                              //   name = name + "(${item.title})";
                              // }
                              // TextEditingController controller = TextEditingController(text: name);
                              // var newName = await showDialog<String>(
                              //     context: context,
                              //     builder: (context) {
                              //       var theme = Theme.of(context);
                              //       return AlertDialog(
                              //         title: Text(kt("directory_name")),
                              //         content: TextField(
                              //           controller: controller,
                              //           autofocus: true,
                              //         ),
                              //         actions: [
                              //           MaterialButton(
                              //               child: Text(kt("ok"), style: theme.textTheme.bodyText1?.copyWith(color: theme.primaryColor),),
                              //               onPressed: () {
                              //                 String text = controller.value.text;
                              //                 if (text.isNotEmpty) {
                              //                   Navigator.of(context).pop(text);
                              //                 } else {
                              //                   Fluttertoast.showToast(msg: kt("name_empty"), toastLength: Toast.LENGTH_SHORT);
                              //                 }
                              //               }
                              //           )
                              //         ],
                              //       );
                              //     }
                              // );
                              // if (newName != null) name = newName;
                              // name = name.replaceAll("/", " ");
                              // Directory dir = Directory(folderPath + "/$name");
                              // if (!await dir.exists()) {
                              //   dir.create();
                              // }
                              //
                              // var subtimes = item.getSubItems();
                              // List<String> urls = subtimes.map<String>((element) => element.picture).toList();
                              // int len = math.max(urls.length.toString().length, 4);
                              //
                              // for (int i = 0, t = urls.length; i < t; ++i) {
                              //   var url = urls[i];
                              //   var file = await queueItem.cacheManager.getFileFromCache(Uri.parse(url));
                              //   if ((await file.stat()).size > 0) {
                              //     String index = i.toString();
                              //     for (int j = index.length; j < len; ++j) {
                              //       index = "0" + index;
                              //     }
                              //     var uri = Uri.parse(url);
                              //     await file.copy("${dir.path}/p_$index${path.extension(uri.path)}");
                              //   } else {
                              //     print("No output $url");
                              //   }
                              // }
                              // item.release();
                              // Fluttertoast.showToast(
                              //     msg: kt("output_to").replaceFirst("{0}", dir.path)
                              // );
                              // Navigator.of(context).pop();
                            },
                            fsType: FilesystemType.folder,
                            fileTileSelectMode: FileTileSelectMode.checkButton
                        );
                      }
                  ));
                } else {
                  Fluttertoast.showToast(
                    msg: kt("no_card_found"),
                    toastLength: Toast.LENGTH_LONG
                  );
                }
              }
            )
                :
            (
                queueItem.state == DownloadState.Downloading ?
                MaterialButton(
                  padding: EdgeInsets.only(left: 8, right: 8),
                  minWidth: IconSize,
                  child: Container(
                    width: IconSize,
                    height: IconSize,
                    child: Icon(Icons.pause, size: 14, color: Colors.black54),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(IconSize/2)),
                        border: Border.all(
                          color: Colors.black54,
                          width: 2,
                        )
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      queueItem.stop();
                    });
                  },
                ) :
                MaterialButton(
                  padding: EdgeInsets.only(left: 8, right: 8),
                  minWidth: IconSize,
                  child: Container(
                    width: IconSize,
                    height: IconSize,
                    child: Icon(Icons.play_arrow, size: 14, color: Colors.black54),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(IconSize/2)),
                        border: Border.all(
                          color: Colors.black54,
                          width: 2,
                        )
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      queueItem.start();
                    });
                  }
                )
            ),
          ),
          Icon(Icons.chevron_right)
        ],
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    String errorString(DownloaderException error) {
      return "${kt(error.label)}: ${error.reason}";
    }

    DownloadQueueItem queueItem = widget.item;
    ThemeData theme = Theme.of(context);
    String title = "";
    if (queueItem.info.data is Map) {
      title = (queueItem.info.data as Map)["title"] ?? "";
    }
    return Column(
      children: [
        Container(
          color: Colors.grey.withOpacity(0.1),
          padding: EdgeInsets.only(left: 10, right: 10),
          child: ListTile(
            title: Text(title),
            subtitle: queueItem.value.hasError ?
            Text(errorString(queueItem.value.error),
              style: theme.textTheme.caption?.copyWith(color: theme.errorColor),) :
            Text("(${queueItem.loaded}/${queueItem.total})",
              style: theme.textTheme.caption,) ,
            trailing: extendButtons(context, queueItem),
            onTap: widget.onTap,
          ),
        ),
        Divider(height: 1,)
      ],
    );
  }

  @override
  void initState() {
    widget.item.addListener(_update);
    super.initState();
  }

  @override
  void dispose() {
    widget.item.removeListener(_update);
    super.dispose();
  }

  void _update() {
    setState(() {
    });
  }
}


class DownloadPage extends StatefulWidget {
  DownloadPage({Key? key}) : super(key: key,);

  @override
  State<StatefulWidget> createState() => _DownloadPageState();
}

class _NeedRemove {
  CellData mainData;
  DownloadQueueItem downloadItem;

  _NeedRemove(this.mainData, this.downloadItem);
}

class _DownloadKey extends GlobalObjectKey {
  _DownloadKey(Object value) : super(value);

}

class _DownloadPageState extends State<DownloadPage> {
  late List<CellData> data;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  _DownloadPageState();

  void clickBookCell(int index) async {
    CellData cdata = data[index];
    switch (cdata.type) {
      case _CellType.Book: {
        BookData bookData = cdata.data;
        if (cdata.extend) {
          int start = index + 1;
          for (int i = start; i < data.length;) {
            CellData ndata = data[i];
            if (ndata.type != _CellType.Chapter) {
              break;
            }
            data.removeAt(i);
            _listKey.currentState?.removeItem(i, (context, animation) {
              DownloadQueueItem queueItem = ndata.data;
              return SizeTransition(
                sizeFactor: animation,
                child: ChapterCell(queueItem),
              );
            });
          }
        } else {
          if (bookData.items.length > 0) {
            List<CellData> list = [];
            for (int i = 0, t = bookData.items.length; i < t; ++i) {
              list.add(CellData(
                  type: _CellType.Chapter,
                  data: bookData.items[i]
              ));
            }
            data.insertAll(index + 1, list);
            for (int offset = 0; offset < list.length; offset++) {
              _listKey.currentState?.insertItem(index + 1 + offset);
            }
          }
        }
        cdata.extend = !cdata.extend;
        break;
      }
      case _CellType.Chapter: {
        DownloadQueueItem queueItem = cdata.data;
        Plugin? plugin = PluginsManager.instance.findPlugin(queueItem.pluginID);
        if (plugin?.isValidate == true) {
          enterFullscreenMode();
          await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            return PictureViewer(
              plugin: plugin!,
              list: [
                queueItem.info.data,
              ],
              initializeIndex: 0,
            );
          }));
          exitFullscreenMode();
        } else {
          Fluttertoast.showToast(msg: kt("no_project_found"));
        }
        break;
      }
    }
  }

  removeItem(_NeedRemove item) {
    setState(() {
      DownloadManager().removeKey(item.downloadItem.info.key);
    });
  }

  Widget cellWithData(int index) {
    CellData cdata = data[index];
    switch (cdata.type) {
      case _CellType.Book: {
        BookData downloadData = cdata.data;
        return Column(
          key: _DownloadKey(cdata),
          children: <Widget>[
            ListTile(
              tileColor: Theme.of(context).colorScheme.surface,
              title: Text(downloadData.bookInfo.title),
              subtitle: Text(downloadData.bookInfo.subtitle??""),
              leading: Image(
                key: ObjectKey(downloadData.bookInfo.picture),
                image: NeoImageProvider(
                  uri: Uri.parse(downloadData.bookInfo.picture??""),
                  cacheManager: NeoCacheManager.defaultManager
                ),
                fit: BoxFit.cover,
                width: 56,
                height: 56,
                gaplessPlayback: true,
                errorBuilder: (context, e, stack) {
                  return Container(
                    width: 56,
                    height: 56,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                  );
                },
              ),
              trailing: AnimatedCrossFade(
                firstChild: Icon(Icons.keyboard_arrow_up),
                secondChild: Icon(Icons.keyboard_arrow_down),
                crossFadeState: cdata.extend ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                duration: Duration(milliseconds: 300)
              ),
              onTap: () {
                clickBookCell(index);
              },
            ),
            Divider(
              height: 1,
            )
          ],
        );
      }
      case _CellType.Chapter: {
          DownloadQueueItem queueItem = cdata.data;
          return Dismissible(
            key: _DownloadKey(cdata),
            child: ChapterCell(
              queueItem,
              onTap: () {
                clickBookCell(index);
              },
            ),
            confirmDismiss: (DismissDirection direction) {
              return showDialog<bool>(
                  context: context,
                  builder: (context) {
                    String title = "";
                    if (queueItem.info.data is Map) {
                      title = (queueItem.info.data as Map)['title'] ?? "";
                    }
                    return AlertDialog(
                      title: Text(kt("confirm")),
                      content: Text(
                          kt("delete_item")
                              .replaceAll("{0}", queueItem.info.title)
                              .replaceAll("{1}", title)
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(kt('no')),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: Text(kt('yes')),
                        ),
                      ],
                    );
                  }
              );
            },
            onDismissed: (DismissDirection direction) async {

              int index = data.indexOf(cdata);
              CellData? mainData;
              for (int i = index - 1; i >= 0; --i) {
                CellData cellData = data[i];
                if (cellData.type == _CellType.Book) {
                  mainData = cellData;
                  BookData bookData = mainData.data;
                  bookData.items.remove(queueItem);
                  break;
                }
              }

              if (mainData != null) {
                _NeedRemove item = _NeedRemove(mainData, queueItem);
                data.removeAt(index);
                _listKey.currentState?.removeItem(index, (context, animation) {
                  return SizeTransition(
                    sizeFactor: animation,
                    child: Container(),
                  );
                });

                removeItem(item);
              }
            },
          );
        }
    }
  }

  Widget animationItem(int idx, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: cellWithData(idx),
    );
  }

  final GlobalKey iconKey = GlobalKey();
  @override
  List<Widget> buildActions(BuildContext context) {
    bool has = KeyValue.get("$viewed_key:download") == "true";
    return [
      IconButton(
        key: iconKey,
        onPressed: () {
          showInstructionsDialog(context, 'assets/download',
            entry: kt('lang'),
          );
        },
        icon: Icon(Icons.help_outline),
        color: has ? Theme.of(context).appBarTheme.iconTheme?.color : Colors.transparent,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kt('download_list')),
        actions: buildActions(context),
      ),
      body: data.length > 0 ? AnimatedList(
        key: _listKey,
        initialItemCount: data.length,
        itemBuilder: (context, index, Animation<double> animation) {
          return animationItem(index, animation);
        },
      ) : NoData(),
    );
  }

  @override
  void initState() {

    data = [];
    List<DownloadQueueItem> items = DownloadManager().items.data;
    Map<String, BookData> cache = Map();
    for (int i = 0, t = items.length; i < t; ++i) {
      DownloadQueueItem item = items[i];
      BookData? downloadItem;
      if (cache.containsKey(item.info.link)) {
        downloadItem = cache[item.info.link]!;
      }
      if (downloadItem == null) {
        downloadItem = BookData(item.info);
        cache[item.info.link] = downloadItem;
        data.add(CellData(
          type: _CellType.Book,
          data: downloadItem
        ));
      }
      downloadItem.items.add(item);
    }
    for (int i = 0, t = data.length; i < t; ++i) {
      CellData cdata = data[i];
      BookData downloadItem = cdata.data;
      downloadItem.items.sort((item1, item2) => item1.info.chapterName.compareTo(item2.info.chapterName));
    }

    super.initState();

    if (KeyValue.get("$viewed_key:download") != "true") {
      Future.delayed(Duration(milliseconds: 300)).then((value) async {
        await showInstructionsDialog(context, 'assets/download',
            entry: kt('lang'),
            onPop: () async {
              final renderObject = iconKey.currentContext?.findRenderObject();
              Rect? rect = renderObject?.paintBounds;
              var translation = renderObject?.getTransformTo(null).getTranslation();
              if (rect != null && translation != null) {
                return rect.shift(Offset(translation.x, translation.y));
              }
              return Rect.zero;
            }
        );
        KeyValue.set("$viewed_key:download", "true");
        // AppStatusNotification().dispatch(context);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}