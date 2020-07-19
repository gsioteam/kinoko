
import 'dart:ui';

import 'package:cache_image/cache_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/core/array.dart';
import 'package:glib/core/callback.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:kinoko/localizations/localizations.dart';
import 'widgets/better_refresh_indicator.dart';
import 'package:glib/main/error.dart' as glib;

class BookPage extends StatefulWidget {

  Context context;

  BookPage(this.context);

  @override
  State<StatefulWidget> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {

  BetterRefreshIndicatorController refreshController = BetterRefreshIndicatorController();
  Array chapters;
  bool editing = false;
  bool reverse = false;

  Widget createItem(BuildContext context, int idx) {
    DataItem item = chapters[idx];
    String subtitle = item.subtitle;
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(item.title),
          subtitle: (subtitle == null || subtitle.length == 0) ? null : Text(subtitle),
        ),
        Divider(height: 3,)
      ],
    );
  }

  Widget buildTitle(DataItem item, ThemeData theme) {
    List<InlineSpan> spans = [
      TextSpan(
        text: item.title,
        style: theme.textTheme.headline2.copyWith(color: Colors.white, fontSize: 14),
      ),
    ];
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

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
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
                        IconButton(
                            icon: Icon(Icons.sort),
                            color: theme.primaryColor,
                            onPressed: (){}
                        ),
                        IconButton(
                            icon: Icon(Icons.file_download),
                            color: theme.primaryColor,
                            onPressed: (){}
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
                      image: CacheImage(data.picture),
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
                            colors: [Color.fromRGBO(0, 0, 0, 0), Color.fromRGBO(0, 0, 0, 0.5)],
                            stops: [0.4, 1]
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                IconButton(
                    icon: Icon(Icons.favorite),
                    onPressed: (){}
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
        onRefresh: onPullDownRefresh,
      ),
    );
  }

  bool onPullDownRefresh() {
    widget.context.reload();
    return false;
  }


  void onDataChanged(Array data, int type) {
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

  @override
  void initState() {
    widget.context.on_data_changed = Callback.fromFunction(onDataChanged).release();
    widget.context.on_loading_status = Callback.fromFunction(onLoadingStatus).release();
    widget.context.on_error = Callback.fromFunction(onError).release();
    widget.context.enterView();
    chapters = widget.context.data.control();
    super.initState();
  }

  @override
  void dispose() {
    widget.context.exitView();
    chapters.release();
    super.dispose();
  }
}