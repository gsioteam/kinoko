

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
import 'package:glib/main/project.dart';
import 'utils/children_delegate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'book_page.dart';
import 'widgets/better_refresh_indicator.dart';
import 'widgets/book_item.dart';

class BookListPage extends StatefulWidget {
  Project project;
  Context context;
  BookListPage(this.project, this.context);

  @override
  State<StatefulWidget> createState()=>_BookListPageState();

}

class _BookListPageState extends State<BookListPage> {
  Array books;
  BetterRefreshIndicatorController controller = BetterRefreshIndicatorController();
  bool cooldown = true;

  void itemClicked(int idx) async {
    Context ctx = widget.project.createBookContext(books[idx]).control();
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => BookPage(ctx, widget.project)
    ));
    ctx.release();
  }

  bool onPullDownRefresh() {
    widget.context.reload();
    return false;
  }

  void onDataChanged(int type, Array data, int idx) {
    if (data != null) {
      setState(() {});
    }
  }

  void onLoadingStatus(bool isLoading) {
    if (isLoading) {
      controller.startLoading();
    } else {
      controller.stopLoading();
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
    widget.context.control();
    widget.context.on_data_changed = Callback.fromFunction(onDataChanged).release();
    widget.context.on_loading_status = Callback.fromFunction(onLoadingStatus).release();
    widget.context.on_error = Callback.fromFunction(onError).release();
    controller.onRefresh = onPullDownRefresh;
    widget.context.enterView();
    books = widget.context.data.control();
    super.initState();
  }

  Widget cellWithData(DataItem item, int idx) {
    return makeBookItem(context, item, () {
      itemClicked(idx);
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      child: BetterRefreshIndicator(
        child: buildMain(context),
        controller: controller,
      ),
      onNotification: (ScrollUpdateNotification notification) {
        if (notification.metrics.maxScrollExtent - notification.metrics.pixels < 20 && cooldown) {
          widget.context.loadMore();
          cooldown = false;
          Future.delayed(Duration(seconds: 2)).then((value) => cooldown = true);
        }
        return false;
      },
    );
  }

  Widget buildMain(BuildContext context) {
    if (books.length == 0) {
      return ListView(
        children: <Widget>[
          Center(
            child: Text("no data!"),
          )
        ],
      );
    } else {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (BuildContext context, int idx) {
          DataItem book = books[idx];
          return cellWithData(book, idx);
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(),
        itemCount: books.length,
      );
    }
  }

  @override
  void dispose() {
    widget.context.on_data_changed = null;
    widget.context.on_loading_status = null;
    widget.context.on_error = null;
    widget.context.exitView();
    books.release();
    widget.context.release();
    super.dispose();
  }
}