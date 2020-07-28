
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
      }
    }
  }

  Widget cellWithData(int index) {
    CellData cdata = data[index];
    switch (cdata.type) {
      case _CellType.Book: {
        BookData downloadData = cdata.data;
        return ListTile(
          title: Text(downloadData.bookInfo.title),
          subtitle: Text(downloadData.bookInfo.subtitle),
          leading: Image(image: CacheImage(downloadData.bookInfo.picture)),
          trailing: Icon(Icons.keyboard_arrow_down),
          onTap: () {
            clickBookCell(index);
          },
        );
      }
      case _CellType.Chapter: {
        DownloadQueueItem queueItem = cdata.data;
        DataItem item = queueItem.item;
        return ListTile(
          title: Text(item.title),
          trailing: Icon(Icons.chevron_right),
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

    super.initState();
  }
}