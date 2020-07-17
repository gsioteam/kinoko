

import 'dart:async';

import 'package:cache_image/cache_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glib/core/array.dart';
import 'package:glib/core/gmap.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/context.dart';
import 'package:glib/core/callback.dart';
import 'package:glib/main/error.dart' as glib;
import 'utils/children_delegate.dart';

class _RefreshIndicatorController {
  _RefreshIndicator target;
  bool loading = false;
  Completer<void> completer = Completer<void>();

  Future<void> onRefresh() async {
    if (!loading && target.onExRefresh != null && target.onExRefresh()) {
      loading = true;
    }
    if (loading) return completer.future;
  }

  void startLoading() {
    if (!loading) {
      loading = true;
      if (target == null && target.state == null) {
        print("show ref");
        target.state.show();
      } else {
        print("Fatal error! ${target == null ? "target" : "state"}");
      }
    } else {
      print("already loading!");
    }
  }

  void stopLoading() {
    if (loading) {
      loading = false;
      completer.complete();
      completer = Completer<void>();
    }
  }
}

class _RefreshIndicator extends RefreshIndicator {

  RefreshIndicatorState state;
  _RefreshIndicatorController controller;
  bool Function() onExRefresh;

  _RefreshIndicator({
    Key key,
    @required Widget child,
    double displacement = 40.0,
    Color color,
    Color backgroundColor,
    ScrollNotificationPredicate notificationPredicate = defaultScrollNotificationPredicate,
    String semanticsLabel,
    String semanticsValue,
    double strokeWidth = 2.0,
    @required _RefreshIndicatorController controller,
    bool Function() onRefresh,
  }) : super(
    key: key,
    child: child,
    displacement: displacement,
    color: color,
    backgroundColor: backgroundColor,
    notificationPredicate: notificationPredicate,
    semanticsLabel: semanticsLabel,
    semanticsValue: semanticsValue,
    strokeWidth: strokeWidth,
    onRefresh: controller.onRefresh
  ) {
    this.controller = controller;
    onExRefresh = onRefresh;
    controller.target = this;
  }

  @override
  RefreshIndicatorState createState() {
    return state = super.createState();
  }
}

class BookListPage extends StatefulWidget {
  Context context;
  int index;
  BookListPage(this.context, this.index);

  @override
  State<StatefulWidget> createState()=>_BookListPageState();

}

class _BookListPageState extends State<BookListPage> {
  Array books;
  _RefreshIndicatorController controller = _RefreshIndicatorController();

  void itemClicked(int idx) {

  }

  bool onPullDownRefresh() {
    print("refresh");
    widget.context.reload();
    return false;
  }

  void onDataChanged(Array data, int type) {
    print("onDataChanged ${data.length}");
    setState(() {});
  }

  void onLoadingStatus(bool isLoading) {
    print("onLoadingStatus ${isLoading}");
    if (isLoading) {
      controller.startLoading();
    } else {
      controller.stopLoading();
    }
  }

  void onError(glib.Error error) {

  }

  @override
  void initState() {
    widget.context.on_data_changed = Callback.fromFunction(onDataChanged).release();
    widget.context.on_loading_status = Callback.fromFunction(onLoadingStatus).release();
    widget.context.on_error = Callback.fromFunction(onError).release();
    widget.context.enterView();
    books = widget.context.data.control();
    print("Setup! ${widget.index}");
    super.initState();
  }

  Widget cellWithData(DataItem item, int idx) {
    if (item.type == DataItemType.Header) {
      return Container(
        padding: EdgeInsets.fromLTRB(5, 2, 5, 2),
        height: 30,
        child: Row(
          children: <Widget>[
            Image(
              image: CacheImage(item.picture),
              width: 26,
              height: 26,
            ),
            Padding(padding: EdgeInsets.all(5)),
            Text(item.title, style: Theme.of(context).textTheme.subtitle1,)
          ],
        ),
      );
    } else {
      return ListTile(
        title: Text(item.title),
        subtitle: Text(item.subtitle),
        leading: Image(
          image: CacheImage(item.picture),
        ),
        onTap: (){
          itemClicked(idx);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RefreshIndicator(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (BuildContext context, int idx) {
          DataItem book = books[idx];
          return cellWithData(book, idx);
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(),
        itemCount: books.length
      ),
      controller: controller,
      onRefresh: onPullDownRefresh,
    );
  }

  @override
  void dispose() {
    print("dispose ${widget.index}");
    widget.context.exitView();
    books.release();
    super.dispose();
  }
}