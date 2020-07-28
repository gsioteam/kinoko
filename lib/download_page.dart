
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

  CellData({
    this.type,
    this.data
  });
}

class ChapterCell extends StatefulWidget {

  DownloadQueueItem item;
  void Function() onTap;

  ChapterCell(this.item, {
    this.onTap
  });

  @override
  State<StatefulWidget> createState() => _ChapterCellState();
}

class _ChapterCellState extends State<ChapterCell> {
  String errorStr;

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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
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
            ),
            Icon(Icons.chevron_right)
          ],
        ),
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

class DownloadPage extends HomeWidget {
  @override
  State<StatefulWidget> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  List<CellData> data;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

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
              DataItem item = queueItem.item;
              return SizeTransition(
                sizeFactor: animation,
                child: ListTile(
                  title: Text(item.title),
                  trailing: Icon(Icons.chevron_right),
                ),
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
              title: Text(downloadData.bookInfo.title),
              subtitle: Text(downloadData.bookInfo.subtitle),
              leading: Image(
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
          onTap: () {
            clickBookCell(index);
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
}