
import 'dart:collection';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/core/array.dart';
import 'package:glib/core/callback.dart';
import 'package:glib/core/core.dart';
import 'package:glib/core/data.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/models.dart';
import 'package:glib/main/project.dart';
import 'package:kinoko/collection_page.dart';
import 'package:xml_layout/xml_layout.dart';
import 'configs.dart';
import 'localizations/localizations.dart';
import 'main.dart';
import 'utils/download_manager.dart';
import 'utils/history_manager.dart';
import 'widgets/better_refresh_indicator.dart';
import 'package:glib/main/error.dart' as glib;
import 'picture_viewer.dart';
import 'utils/book_info.dart';
import 'utils/favorites_manager.dart';
import 'utils/proxy_collections.dart';
import 'widgets/collection_view.dart';
import 'widgets/instructions_dialog.dart';
import 'widgets/source_page.dart';

class _DefaultBookPage extends StatefulWidget {
  final Context context;
  final Project project;
  final void Function(DataItem) onTap;
  final void Function(DataItem) onDownload;
  final Array chapters;
  final DataItem lastChapter;

  _DefaultBookPage({
    this.context,
    this.project,
    this.onTap,
    this.chapters,
    this.lastChapter,
    this.onDownload,
  });

  @override
  State<StatefulWidget> createState() => _DefaultBookPageState();
}

class _DefaultBookPageState extends State<_DefaultBookPage> {
  BetterRefreshIndicatorController refreshController = BetterRefreshIndicatorController();
  bool editing = false;
  int orderIndex = 0;

  static const String ORDER_TYPE = "order";

  static const int ORDER = 1;
  static const int R_ORDER = 0;

  Set<int> selected = Set();

  Widget createItem(int idx) {
    String temp = "";
    DataItem item = widget.chapters[idx];
    if (temp.isEmpty) {
      if (item.type != DataItemType.Header) {
        String subtitle = item.subtitle;
        DownloadQueueItem downloadItem = DownloadManager().find(item);

        return ChapterItem(
          title: item.title,
          subtitle: subtitle,
          editing: editing,
          selected: selected.contains(idx),
          downloadItem: downloadItem,
          onTap: () {
            onSelectItem(idx);
          },
        );
      } else {
        return Column(
          children: [
            ListTile(
              title: Text(item.title),
            ),
            Divider(height: 3,)
          ],
        );
      }
    } else {
      return XmlLayout(
        template: temp,
        objects: {
          "data": _itemMap(item),
          "onClick": () {
            onSelectItem(idx);
          }
        },
        onUnkownElement: (node, key) {
          print("Unkown type $node");
        },
      );
    }
  }

  Widget buildTitle(DataItem item, ThemeData theme) {
    String link = item.link;
    List<InlineSpan> spans = [
      TextSpan(
        text: item.title,
        style: theme.textTheme.headline2.copyWith(color: Colors.white, fontSize: 14),
      ),
      WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: TextButton(
            style: ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: MaterialStateProperty.all(EdgeInsets.only(left: 4, right: 4, top: 1, bottom: 1)),
              minimumSize: MaterialStateProperty.all(Size.zero),
            ),
            child: Text(
              "[${kt("source")}]",
              style: TextStyle(
                  fontSize: 6
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return SourcePage(
                  url: link,
                );
              }));
            },
          )
      )
    ];

    String subtitle = item.subtitle;
    if (subtitle != null && subtitle.isNotEmpty) {
      spans.add(WidgetSpan(child: Padding(padding: EdgeInsets.only(top: 5),)));
      spans.add(TextSpan(
        text: "\n${item.subtitle}",
        style: theme.textTheme.bodyText2.copyWith(color: Colors.white, fontSize: 8),
      ));
    }

    String summary = item.summary;
    if (summary != null && summary.isNotEmpty) {
      spans.add(WidgetSpan(child: Padding(padding: EdgeInsets.only(top: 5),)));
      spans.add(TextSpan(
        text: "\n${item.summary}",
        style: theme.textTheme.bodyText2.copyWith(color: Colors.white, fontSize: 8),
      ));
    }

    return Text.rich(
      TextSpan(
          children: spans
      ),
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }

  onOrderChanged(int value) {
    setState(() {
      KeyValue.set(key(ORDER_TYPE),value.toString());
      orderIndex = value;
    });
  }

  onDownloadClicked() {
    setState(() {
      editing = true;
    });
  }

  onCancelClicked() {
    setState(() {
      selected.clear();
      editing = false;
    });
  }

  onDownloadStartClicked() {
    selected.forEach((idx) {
      widget.onDownload?.call(widget.chapters[idx]);
    });
    setState(() {
      editing = false;
    });
  }

  onSelectItem(int idx) {
    if (editing) {
      DataItem data = widget.chapters[idx];
      if (data.isInCollection(collection_download)) {
      } else {
        setState(() {
          if (selected.contains(idx)) {
            selected.remove(idx);
          } else {
            selected.add(idx);
          }
        });
      }
    } else {
      int currentIndex = idx;
      DataItem data = widget.chapters[currentIndex];
      openChapter(data);
    }
  }

  void openChapter(DataItem chapter) {
    widget.onTap?.call(chapter);
  }

  void openCollection(Map data, String title) async {
    widget.project.control();
    Context scriptContext = widget.project.createIndexContext(data).control();

    await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return CollectionPage(
        title: title,
        context: scriptContext,
        project: widget.project,
      );
    }));

    scriptContext.release();
    widget.project.release();
  }

  Widget makeLastChapter() {
    DataItem item = widget.lastChapter;
    var theme = Theme.of(context);
    return Expanded(
        child: Container(
          padding: EdgeInsets.only(left: 5, right: 5),
          alignment: Alignment.centerLeft,
          child: Visibility(
            visible: item != null,
            child: TextButton(
              onPressed: () {
                openChapter(widget.lastChapter);
              },
              child: Text(
                  "[${item?.title}]",
                  style: theme.textTheme.bodyText2.copyWith(color: theme.primaryColor),
                  overflow: TextOverflow.ellipsis
              ),
            ),
          ),
        )
    );
  }

  bool onPullDownRefresh() {
    widget.context.reload();
    return false;
  }

  void favoriteClicked() {
    setState(() {
      DataItem data = widget.context.infoData;
      if (FavoritesManager().isFavorite(data)) {
        FavoritesManager().remove(data);
      } else {
        FavoritesManager().add(data);
      }
    });
  }

  void onDataChanged(int type, Array data, int idx) {
    if (data != null) {
      setState(() {});
    }
  }

  void onLoadingStatus(bool isLoading) {
    if (isLoading) {
      refreshController.startLoading();
    } else {
      refreshController.stopLoading();
    }
  }

  void onError(glib.Error error) {
    Fluttertoast.showToast(
      msg: error.msg,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  dynamic onCall(String name, Array argv) {

    return null;
  }

  String key(String type) => "$type:${widget.context.infoData.link}";
  AutoRelease data;

  Map<String, dynamic> _itemMap(DataItem item) {
    data?.release();
    data = item.data?.control();
    return {
      "title": item.title,
      "data": proxyObject(data),
      "summary": item.summary,
      "picture": item.picture,
      "subtitle": item.subtitle,
      "link": item.link,
      "type": item.type
    };
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    var data = widget.context.infoData;
    if (!(data is DataItem)) {
      return Container(
        child: Text("Wrong type"),
        color: Colors.red,
      );
    }

    return Scaffold(
      body: BetterRefreshIndicator(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              brightness: Brightness.dark,
              floating: true,
              pinned: true,
              backgroundColor: theme.primaryColor,
              expandedHeight: 288.0,
              bottom: PreferredSize(
                  child: Container(
                    height: 48,
                    color: Colors.white,
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.bookmark, color: theme.primaryColor, size: 14,),
                        Text(kt("chapters")),
                        makeLastChapter(),
                        // Expanded(child: Container()),
                        PopupMenuButton(
                            onSelected: onOrderChanged,
                            icon: Icon(Icons.sort, color: theme.primaryColor,),
                            itemBuilder: (context) {
                              return [
                                CheckedPopupMenuItem<int>(
                                    value: R_ORDER,
                                    checked: orderIndex == R_ORDER,
                                    child: Text(kt("reverse_order"))
                                ),

                                CheckedPopupMenuItem<int>(
                                    value: ORDER,
                                    checked: orderIndex == ORDER,
                                    child: Text(kt("order"))
                                )
                              ];
                            }
                        ),
                        BarItem(
                          display: editing,
                          child: IconButton(
                              icon: Icon(Icons.clear),
                              color: theme.primaryColor,
                              onPressed: onCancelClicked
                          ),
                        ),
                        BarItem(
                          display: editing,
                          child: IconButton(
                              icon: Icon(Icons.check),
                              color: theme.primaryColor,
                              onPressed: onDownloadStartClicked
                          ),
                        ),
                        BarItem(
                          display: !editing,
                          child: IconButton(
                              icon: Icon(Icons.file_download),
                              color: theme.primaryColor,
                              onPressed: onDownloadClicked
                          ),
                        ),
                      ],
                    ),
                  ),
                  preferredSize: Size(double.infinity, 48)
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: buildTitle(data, theme),
                titlePadding: EdgeInsets.only(left: 20, bottom: 64),
                background: Stack(
                  children: <Widget>[
                    Image(
                      width: double.infinity,
                      height: double.infinity,
                      image: CachedNetworkImageProvider(data.picture),
                      gaplessPlayback: true,
                      fit: BoxFit.cover,
                    ),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX:  4, sigmaY: 4),
                      child: Container(
                        color: Colors.black.withOpacity(0),
                      ),
                    ),
                    Container(
                      alignment: Alignment.bottomLeft,
                      width: double.infinity,
                      height: double.infinity,
                      padding: EdgeInsets.fromLTRB(14, 10, 14, 58),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color.fromRGBO(0, 0, 0, 0.5), Color.fromRGBO(0, 0, 0, 0), Color.fromRGBO(0, 0, 0, 0.5)],
                            stops: [0, 0.4, 1]
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                IconButton(
                    icon: Icon(Icons.favorite),
                    color: FavoritesManager().isFavorite(data) ? Colors.red : Colors.white,
                    onPressed: favoriteClicked
                ),
              ],
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, idx) {
                  if (orderIndex == ORDER) {
                    idx = widget.chapters.length - idx - 1;
                  }
                  return createItem(idx);
                },
                childCount: widget.chapters.length,
              ),
            )
          ],
        ),
        controller: refreshController,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.project.control();
    widget.context.control();
    widget.context.onDataChanged = Callback.fromFunction(onDataChanged).release();
    widget.context.onLoadingStatus = Callback.fromFunction(onLoadingStatus).release();
    widget.context.onError = Callback.fromFunction(onError).release();
    widget.context.onCall = Callback.fromFunction(onCall).release();
    refreshController.onRefresh = onPullDownRefresh;
    widget.context.enterView();
    FavoritesManager().clearNew(widget.context.infoData);
    HistoryManager().insert(widget.context.infoData);
    String order = KeyValue.get(key(ORDER_TYPE));
    if (order != null && order.isNotEmpty) {
      try {
        orderIndex = int.parse(order);
      } catch (e) { }
    }
  }

  @override
  void dispose() {
    super.dispose();

    widget.context.exitView();
    widget.context.release();
    widget.project.release();
    data?.release();
  }

}

class BarItem extends StatefulWidget {

  final bool display;
  final Widget child;

  BarItem({
    this.display = false,
    @required this.child
  });

  @override
  State<StatefulWidget> createState() => BarItemState();
}

class BarItemState extends State<BarItem> with SingleTickerProviderStateMixin {

  AnimationController controller;
  Animation<double> _animation;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      axis: Axis.horizontal,
      sizeFactor: _animation,
      child: widget.child,
    );
  }

  @override
  void didUpdateWidget(BarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.display != widget.display) {
      if (widget.display) {
        controller.forward();
      } else {
        controller.reverse();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
      reverseDuration: Duration(milliseconds: 300)
    );
    
//    _animation = controller;
    _animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic
    );
    controller.value = widget.display ? 1 : 0;
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }
}

class ChapterItem extends StatefulWidget {

  bool editing;
  bool selected;
  String title;
  String subtitle;
  DownloadQueueItem downloadItem;
  void Function() onTap;

  ChapterItem({
    this.editing = false,
    this.title,
    this.subtitle,
    this.downloadItem,
    this.selected = false,
    this.onTap
  });

  @override
  State<StatefulWidget> createState() => _ChapterItemState();

}

class _ChapterItemState extends State<ChapterItem> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(widget.title),
          subtitle: (widget.subtitle == null || widget.subtitle.length == 0) ? null : Text(widget.subtitle, style: Theme.of(context).textTheme.caption.copyWith(fontSize: 8),),
          trailing:
          widget.downloadItem == null ?
          AnimatedOpacity(
            opacity: widget.editing ? 1 : 0,
            child: Icon(
                widget.selected ? Icons.radio_button_checked : Icons.radio_button_unchecked
            ),
            duration: Duration(milliseconds: 300),
          ) :
          Text(
            "${widget.downloadItem.loaded}/${widget.downloadItem.total}",
            style: Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.black26, fontSize: 12),
          ),
          onTap: widget.onTap,
        ),
        Divider(height: 1,)
      ],
    );
  }

  onProgress() {
    setState(() {});
  }

  @override
  void initState() {
    if (widget.downloadItem != null) {
      widget.downloadItem.onProgress = onProgress;
    }
    super.initState();
  }

  @override
  void didUpdateWidget(ChapterItem oldWidget) {
    if (oldWidget.downloadItem != null) {
      oldWidget.downloadItem = null;
    }
    if (widget.downloadItem != null) {
      widget.downloadItem.onProgress = onProgress;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    if (widget.downloadItem != null) {
      widget.downloadItem.onProgress = null;
    }
    super.dispose();
  }
}

class BookPage extends StatefulWidget {

  final Context context;
  final Project project;

  BookPage(this.context, this.project);

  @override
  State<StatefulWidget> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {

  String template;
  Array chapters;

  @override
  Widget build(BuildContext context) {
    if (template.isEmpty) {
      return _DefaultBookPage(
        project: widget.project,
        context: widget.context,
        chapters: chapters,
        lastChapter: lastChapter,
        onTap: (DataItem item) {
          openChapter(item);
        },
        onDownload: downloadItem,
      );
    } else {
      return CollectionView(
        project: widget.project,
        context: widget.context,
        template: template,
        onTap: (DataItem item) {
          openChapter(item);
        },
        extensions: {
          "openChapter": (int chapterIndex, [int pageIndex]) {
            openChapter(widget.context.data[chapterIndex], pageIndex);
          },
          "downloadChapter": (int chapterIndex) {
            downloadItem(widget.context.data[chapterIndex]);
          },
        },
      );
    }
  }

  String _lastChapterKey;
  String _lastChapterValue;
  String get lastChapterKey {
    if (_lastChapterKey == null) {
      DataItem bookItem = widget.context.infoData;
      _lastChapterKey = "$last_chapter_key:${bookItem.projectKey}:${bookItem.link}";
    }
    return _lastChapterKey;
  }

  DataItem lastChapter;
  DataItem _getLastChapter() {
    if (_lastChapterValue == null) {
      _lastChapterValue = KeyValue.get(lastChapterKey);
    }
    if (_lastChapterValue != null && _lastChapterValue.isNotEmpty) {
      Array items = DataItem.fromJSON(_lastChapterValue);
      if (items.isNotEmpty) {
        DataItem item = items.first;
        if (item.projectKey.isEmpty)
          item.projectKey = widget.context.projectKey;
        return item;
      }
      return null;
    }
    return null;
  }

  int _findIndexOfChapter(String link) {
    for (int i = 0, t = chapters.length; i < t; ++i) {
      DataItem chapter = chapters[i];
      if (link == chapter.link) {
        return i;
      }
    }
    return -1;
  }

  void _saveLastChapter(DataItem chapter) {
    setState(() {
      _lastChapterValue = DataItem.toJSON(Array.allocate([chapter]).release());
      KeyValue.set(lastChapterKey, _lastChapterValue);
      lastChapter?.release();
      lastChapter = _getLastChapter()?.control();
    });
  }

  void openChapter(DataItem chapter, [int page]) async {
    _saveLastChapter(chapter);
    int currentIndex = chapters.indexOf(chapter);
    String link = chapter.link;
    widget.project.control();

    Future.delayed(Duration(milliseconds: 100)).then((value) => SystemChrome.setEnabledSystemUIOverlays([]));
    Context currentContext = widget.project.createCollectionContext(CHAPTER_INDEX, chapter).control();
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return PictureViewer(
        currentContext,
        onChapterChanged: (PictureFlipType flipType) {
          if (currentIndex < 0) {
            if ((currentIndex = _findIndexOfChapter(link)) < 0) return null;
          }
          // 倒序排序
          if (flipType == PictureFlipType.Prev) {
            if (currentIndex < chapters.length - 1) {
              currentIndex++;
              DataItem data = chapters[currentIndex];
              _saveLastChapter(data);
              r(currentContext);
              currentContext = widget.project.createCollectionContext(CHAPTER_INDEX, data).control();
              return currentContext;
            }
          } else if (flipType == PictureFlipType.Next) {
            if (currentIndex < 0) {
              if ((currentIndex = _findIndexOfChapter(link)) < 0) return null;
            }
            if (currentIndex > 0) {
              currentIndex--;
              DataItem data = chapters[currentIndex];;
              _saveLastChapter(data);
              r(currentContext);
              currentContext = widget.project.createCollectionContext(CHAPTER_INDEX, data).control();
              return currentContext;
            }
          }
          return null;
        },
        onDownload: (_item) {
          DataItem dataItem = widget.context.infoData;
          setState(() {
            DownloadQueueItem item = DownloadManager().add(_item, BookInfo(
                title: dataItem.title,
                picture: dataItem.picture,
                link: dataItem.link,
                subtitle: dataItem.subtitle
            ));
            item.start();
          });
        },
        startPage: page,
      );
    }));
    currentContext.release();
    widget.project.release();

    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
  }

  void downloadItem(DataItem item) {
    DataItem dataItem = widget.context.infoData;
    DownloadQueueItem downloadItem = DownloadManager().add(item, BookInfo(
        title: dataItem.title,
        picture: dataItem.picture,
        link: dataItem.link,
        subtitle: dataItem.subtitle
    ));
    downloadItem.start();
    setState(() { });
  }

  @override
  void initState() {
    super.initState();
    widget.context.control();
    widget.project.control();
    chapters = widget.context.data.control();
    template = widget.context.temp;

    lastChapter = _getLastChapter()?.control();
  }

  @override
  void dispose() {
    super.dispose();
    widget.context.release();
    widget.project.release();
    chapters.release();
    lastChapter?.release();
  }

}