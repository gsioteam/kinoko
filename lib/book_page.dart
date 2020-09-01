
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/core/array.dart';
import 'package:glib/core/callback.dart';
import 'package:glib/core/core.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/models.dart';
import 'package:glib/main/project.dart';
import 'package:xml_layout/xml_layout.dart';
import 'configs.dart';
import 'localizations/localizations.dart';
import 'utils/download_manager.dart';
import 'widgets/better_refresh_indicator.dart';
import 'package:glib/main/error.dart' as glib;
import 'picture_viewer.dart';
import 'utils/book_info.dart';
import 'utils/favorites_manager.dart';

class BarItem extends StatefulWidget {

  bool display;
  Widget child;

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
        Divider(height: 3,)
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

  Context context;
  Project project;

  BookPage(this.context, this.project);

  @override
  State<StatefulWidget> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {

  BetterRefreshIndicatorController refreshController = BetterRefreshIndicatorController();
  Array chapters;
  bool editing = false;
  int order_index = 0;

  static const String ORDER_TYPE = "order";

  static const int ORDER = 1;
  static const int R_ORDER = 0;

  Set<int> selected = Set();

  Widget createItem(BuildContext context, int idx) {
    if (order_index == ORDER) {
      idx = chapters.length - idx - 1;
    }
    DataItem item = chapters[idx];
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
  }

  Widget buildTitle(DataItem item, ThemeData theme) {
    List<InlineSpan> spans = [
      TextSpan(
        text: item.title,
        style: theme.textTheme.headline2.copyWith(color: Colors.white, fontSize: 14),
      ),
    ];

    String subtitle = item.subtitle;
    if (subtitle != null && !subtitle.isEmpty) {
      spans.add(WidgetSpan(child: Padding(padding: EdgeInsets.only(top: 5),)));
      spans.add(TextSpan(
        text: "\n${item.subtitle}",
        style: theme.textTheme.bodyText2.copyWith(color: Colors.white, fontSize: 8),
      ));
    }

    String summary = item.summary;
    if (summary != null && !summary.isEmpty) {
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
      order_index = value;
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
    setState(() {
      DataItem dataItem = widget.context.info_data;
      selected.forEach((idx) {
        DownloadQueueItem item = DownloadManager().add(chapters[idx], BookInfo(
            title: dataItem.title,
            picture: dataItem.picture,
            link: dataItem.link,
            subtitle: dataItem.subtitle
        ));
        item.start();
      });
      editing = false;
    });
  }

  onSelectItem(int idx) async {
    if (editing) {
      DataItem data = chapters[idx];
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
      DataItem data = chapters[currentIndex];
      widget.project.control();
      Context currentContext = widget.project.createChapterContext(data).control();
      await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return PictureViewer(
          currentContext,
          onChapterChanged: (PictureFlipType flipType) {
            // 倒序排序
            if (flipType == PictureFlipType.Prev) {
              if (currentIndex < chapters.length - 1) {
                currentIndex++;
                DataItem data = chapters[currentIndex];
                r(currentContext);
                currentContext = widget.project.createChapterContext(data).control();
                return currentContext;
              }
            } else if (flipType == PictureFlipType.Next) {
              if (currentIndex > 0) {
                currentIndex--;
                DataItem data = chapters[currentIndex];
                r(currentContext);
                currentContext = widget.project.createChapterContext(data).control();
                return currentContext;
              }
            }
            return null;
          },
          onDownload: (_item) {
            DataItem dataItem = widget.context.info_data;
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
        );
      }));
      currentContext.release();
      widget.project.release();
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    String temp = widget.context.temp;
    if (temp.isEmpty) {
      var data = widget.context.info_data;
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
                          Expanded(child: Container()),
                          PopupMenuButton(
                              onSelected: onOrderChanged,
                              icon: Icon(Icons.sort, color: theme.primaryColor,),
                              itemBuilder: (context) {
                                return [
                                  CheckedPopupMenuItem<int>(
                                      value: R_ORDER,
                                      checked: order_index == R_ORDER,
                                      child: Text(kt("reverse_order"))
                                  ),

                                  CheckedPopupMenuItem<int>(
                                      value: ORDER,
                                      checked: order_index == ORDER,
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
                  createItem,
                  childCount: chapters.length,
                ),
              )
            ],
          ),
          controller: refreshController,
        ),
      );
    } else {
      return XmlLayout(
        template: temp,
        objects: {

        },
      );
    }
  }

  bool onPullDownRefresh() {
    widget.context.reload();
    return false;
  }

  void favoriteClicked() {
    setState(() {
      DataItem data = widget.context.info_data;
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

  String key(String type) {
    return "$type:${widget.context.info_data.link}";
  }

  @override
  void initState() {
    widget.project.control();
    widget.context.control();
    widget.context.on_data_changed = Callback.fromFunction(onDataChanged).release();
    widget.context.on_loading_status = Callback.fromFunction(onLoadingStatus).release();
    widget.context.on_error = Callback.fromFunction(onError).release();
    refreshController.onRefresh = onPullDownRefresh;
    widget.context.enterView();
    FavoritesManager().clearNew(widget.context.info_data);
    chapters = widget.context.data.control();
    String order = KeyValue.get(key(ORDER_TYPE));
    if (order != null && !order.isEmpty) {
      try {
        order_index = int.parse(order);
      } catch (e) { }
    }
    super.initState();
  }

  @override
  void dispose() {
    widget.context.exitView();
    chapters.release();
    widget.context.release();
    widget.project.release();
    super.dispose();
  }
}