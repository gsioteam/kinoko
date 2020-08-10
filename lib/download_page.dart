
import 'package:cache_image/cache_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/project.dart';
import 'package:kinoko/utils/book_info.dart';
import 'package:kinoko/utils/cached_picture_image.dart';
import 'picture_viewer.dart';
import 'utils/download_manager.dart';
import 'localizations/localizations.dart';
import 'widgets/better_snack_bar.dart';

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

  @override
  void dispose() {
    widget.item.onProgress = null;
    widget.item.onState = null;
    widget.item.onError = null;
    super.dispose();
  }
}

class DownloadPage extends HomeWidget {
  DownloadPage() : super(key: GlobalKey<_DownloadPageState>()) {
    this.title = "download_list";
  }

  @override
  State<StatefulWidget> createState() => _DownloadPageState();

}

class _NeedRemove {
  CellData mainData;
  DownloadQueueItem downloadItem;

  _NeedRemove(this.mainData, this.downloadItem);
}

class _DownloadPageState extends State<DownloadPage> {
  List<CellData> data;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  List<_NeedRemove> needRemove = List();
  List<BetterSnackBar<bool>> snackBars = List();

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
        DownloadQueueItem queueItem = cdata.data;
        DataItem item = queueItem.item;
        Project project = Project.allocate(item.projectKey).control();
        Context ctx = project.createChapterContext(item).control();
        await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return PictureViewer(
            ctx,
          );
        }));
        ctx.release();
        project.release();
        break;
      }
    }
  }

  removeItem(_NeedRemove item) {
    if (needRemove.contains(item)) {
      DownloadManager().removeItem(item.downloadItem);
      needRemove.remove(item);
    }
  }

  reverseItem(_NeedRemove item) {
    if (needRemove.contains(item)) {
      if (item.mainData.extend) {
        BookData bookData = item.mainData.data;
        int i, t = bookData.items.length;
        for (i = 0; i < t; ++i) {
          DownloadQueueItem cItem = bookData.items[i];
          if (cItem.item.title.compareTo(item.downloadItem.item.title) >= 0) {
            break;
          }
        }
        bookData.items.insert(i, item.downloadItem);
        int cIndex = data.indexOf(item.mainData);
        int listIndex = cIndex + i + 1;
        data.insert(listIndex, CellData(
          type: _CellType.Chapter,
          data: item.downloadItem
        ));
        _listKey.currentState.insertItem(listIndex);
      } else {
        BookData bookData = item.mainData.data;
        int i, t = bookData.items.length;
        for (i = 0; i < t; ++i) {
          DownloadQueueItem cItem = bookData.items[i];
          if (item.downloadItem.item.title.compareTo(cItem.item.title) >= 0) {
            break;
          }
        }
        bookData.items.insert(i, item.downloadItem);
      }
      needRemove.remove(item);
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
          return Dismissible(
            key: ObjectKey(queueItem),
            child: ChapterCell(
              queueItem,
              onTap: () {
                clickBookCell(index);
              },
            ),
            onDismissed: (DismissDirection direction) async {
              BetterSnackBar<bool> snackBar;
              snackBar = BetterSnackBar(
                title: kt("confirm"),
                subtitle: kt("delete_item").replaceAll("{0}", queueItem.info.title).replaceAll("{1}", queueItem.item.title),
                trailing: FlatButton(
                  child: Text(kt("undo"), style: Theme.of(context).textTheme.bodyText2.copyWith(color: Colors.white, fontWeight: FontWeight.bold),),
                  onPressed: () {
                    snackBar.dismiss(true);
                  },
                ),
                duration: Duration(seconds: 5),
              );

              snackBars.add(snackBar);

              int index = data.indexOf(cdata);
              CellData mainData;
              for (int i = index - 1; i >= 0; --i) {
                CellData cellData = data[i];
                if (cellData.type == _CellType.Book) {
                  mainData = cellData;
                  BookData bookData = mainData.data;
                  bookData.items.remove(queueItem);
                  break;
                }
              }

              _NeedRemove item = _NeedRemove(mainData, queueItem);
              needRemove.add(item);
              data.removeAt(index);
              _listKey.currentState.removeItem(index, (context, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  child: Container(),
                );
              });

              bool result = await snackBar.show(context);
              if (result == true) {
                reverseItem(item);
              } else {
                removeItem(item);
              }

              snackBars.remove(snackBar);
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
    return Scaffold(
      body: AnimatedList(
        key: _listKey,
        initialItemCount: data.length,
        itemBuilder: (context, index, Animation<double> animation) {
          return animationItem(index, animation);
        },
      ),
    );
  }

  @override
  void initState() {

    data = [];
    List<DownloadQueueItem> items = DownloadManager().items;
    Map<String, BookData> cache = Map();
    for (int i = 0, t = items.length; i < t; ++i) {
      DownloadQueueItem item = items[i];
      BookData downloadItem;
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
    snackBars.forEach((element)=>element.dismiss(false));
    snackBars.clear();
    super.dispose();
  }
}