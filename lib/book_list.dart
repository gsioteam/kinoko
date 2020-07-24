

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

class BookListPage extends StatefulWidget {
  Project project;
  Context context;
  int index;
  BookListPage(this.project, this.context, this.index);

  @override
  State<StatefulWidget> createState()=>_BookListPageState();

}

class _BookListPageState extends State<BookListPage> {
  Array books;
  BetterRefreshIndicatorController controller = BetterRefreshIndicatorController();

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
    widget.context.enterView();
    books = widget.context.data.control();
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
              gaplessPlayback: true,
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
          fit: BoxFit.cover,
          width: 56,
          height: 56,
        ),
        onTap: (){
          itemClicked(idx);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BetterRefreshIndicator(
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
    widget.context.exitView();
    books.release();
    widget.context.release();
    super.dispose();
  }
}