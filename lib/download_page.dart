
import 'package:cache_image/cache_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:kinoko/utils/book_info.dart';
import 'package:kinoko/utils/cached_picture_image.dart';
import 'utils/download_manager.dart';

import 'widgets/home_widget.dart';

class BookData {
  BookInfo bookInfo;

  List<DownloadQueueItem> items = List();
}

enum _CellType {
  Book,
  Chapter
}

class CellData {
  _CellType type;
  bool extend = false;
  dynamic data;
  LocalKey key;

  CellData({
    this.type,
    this.data
  }) {
    key = ObjectKey(data);
  }
}

class ChapterCell extends StatefulWidget {

  DownloadQueueItem item;
  void Function() onTap;
  bool editMode = false;

  ChapterCell(this.item, {
    key,
    this.onTap,
    this.editMode = false
  }):super(key: key);

  @override
  State<StatefulWidget> createState() => _ChapterCellState();
}

class _ChapterCellState extends State<ChapterCell> {
  String errorStr;

  Widget extendButtons(BuildContext context, DownloadQueueItem queueItem) {
    if (widget.editMode) {
      return IconButton(
        icon: Icon(Icons.delete_outline),
        onPressed: () {

        },
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            child: queueItem.state == DownloadState.AllComplete ? null : (
                queueItem.downloading ?
                IconButton(
                    icon: Icon(Icons.pause),
                    onPressed: () {
                      setState(() {
                        queueItem.stop();
                      });
                    }
                ):
                IconButton(
                    icon: Icon(Icons.play_arrow),
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
    DownloadQueueItem queueItem = widget.item;
    DataItem item = queueItem.item;
    ThemeData theme = Theme.of(context);
    return Container(
      color: Colors.grey.withOpacity(0.1),
      padding: EdgeInsets.only(left: 10, right: 10),
      child: ListTile(
        title: Text(item.title),
        subtitle: Text("(${queueItem.loaded}/${queueItem.total})", style: theme.textTheme.caption,),
        trailing: extendButtons(context, queueItem),
        onTap: widget.onTap,
      ),
    );
  }

  onProgress() {
    setState(() {});
  }

  onState() {
    setState(() {});
  }

  onError(String err) {
    setState(() {
      errorStr = err;
    });
  }

  @override
  void initState() {
    widget.item.onProgress = onProgress;
    widget.item.onState = onState;
    widget.item.onError = onError;
    super.initState();
  }
}

class _DeleteController {
  bool _editMode = false;
  void Function() onEditModeChange;

  bool get editMode => _editMode;
  set editMode(bool mode) {
    if (_editMode != mode) {
      _editMode = mode;
      onEditModeChange?.call();
    }
  }
}

class DownloadPage extends HomeWidget {
  _DeleteController _controller = _DeleteController();

  DownloadPage() : super(key: GlobalKey<_DownloadPageState>()) {
    this.title = "download_list";
  }

  @override
  State<StatefulWidget> createState() => _DownloadPageState(_controller);

  @override
  List<Widget> buildActions(BuildContext context, reload) {
    return [
      IconButton(
        icon: Icon(_controller.editMode ? Icons.done : Icons.delete),
        onPressed: () {
          _controller.editMode = !_controller.editMode;
          reload();
          GlobalKey<_DownloadPageState> key = this.key;
          key.currentState.setState(() { });
        },
      )
    ];
  }
}

class _DownloadPageState extends State<DownloadPage> {
  List<CellData> data;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  _DeleteController controller;

  _DownloadPageState(this.controller);

  void clickBookCell(int index) {
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
            _listKey.currentState.removeItem(i, (context, animation) {
              DownloadQueueItem queueItem = ndata.data;
              return SizeTransition(
                sizeFactor: animation,
                child: ChapterCell(queueItem),
              );
            });
          }
        } else {
          if (bookData.items.length > 0) {
            List<CellData> list = List(bookData.items.length);
            for (int i = 0, t = bookData.items.length; i < t; ++i) {
              list[i] = CellData(
                type: _CellType.Chapter,
                data: bookData.items[i]
              );
            }
            data.insertAll(index + 1, list);
            for (int offset = 0; offset < list.length; offset++) {
              _listKey.currentState.insertItem(index + 1 + offset);
            }
          }
        }
        cdata.extend = !cdata.extend;
        break;
      }
      case _CellType.Chapter: {
        break;
      }
    }
  }

  Widget cellWithData(int index) {
    CellData cdata = data[index];
    switch (cdata.type) {
      case _CellType.Book: {
        BookData downloadData = cdata.data;
        return Column(
          children: <Widget>[
            ListTile(
              key: cdata.key,
              title: Text(downloadData.bookInfo.title),
              subtitle: Text(downloadData.bookInfo.subtitle),
              leading: Image(
                key: ObjectKey(downloadData.bookInfo.picture),
                image: CacheImage(downloadData.bookInfo.picture),
                fit: BoxFit.cover,
                width: 56,
                height: 56,
                gaplessPlayback: true,
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
        return ChapterCell(
          queueItem,
          key: cdata.key,
          onTap: () {
            clickBookCell(index);
          },
          editMode: controller.editMode,
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

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      initialItemCount: data.length,
      itemBuilder: (context, index, Animation<double> animation) {
        return animationItem(index, animation);
      },
    );
  }

  @override
  void initState() {

    data = [];
    List<DownloadQueueItem> items = DownloadManager().items;
    Map<String, BookData> cache = Map();
    for (int i = 0, t = items.length; i < t; ++i) {
      DownloadQueueItem item = items[i];
      BookData downloadItem = null;
      if (cache.containsKey(item.info.link)) {
        downloadItem = cache[item.info.link];
      }
      if (downloadItem == null) {
        downloadItem = BookData();
        downloadItem.bookInfo = item.info;
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
      downloadItem.items.sort((item1, item2) => item1.item.title.compareTo(item2.item.title));
    }

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }
}