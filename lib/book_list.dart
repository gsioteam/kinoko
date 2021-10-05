

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/context.dart';
import 'package:glib/core/callback.dart';
import 'package:glib/main/error.dart' as glib;
import 'package:glib/main/project.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:xml_layout/xml_layout.dart';
import 'book_page.dart';
import 'configs.dart';
import 'widgets/better_refresh_indicator.dart';
import 'widgets/book_item.dart';
import 'utils/proxy_collections.dart';
import 'widgets/collection_view.dart';

class BookListPage extends StatefulWidget {
  final Project project;
  final Context context;
  BookListPage(this.project, this.context);

  @override
  State<StatefulWidget> createState()=>_BookListPageState();

}

class _BookListPageState extends State<BookListPage> {
  String template;

  @override
  void initState() {
    super.initState();
    widget.context.control();

    template = widget.context.temp;
    if (template.isEmpty)
      template = cachedTemplates["assets/collection.xml"];
  }

  @override
  Widget build(BuildContext context) {
    return CollectionView(
      project: widget.project,
      context: widget.context,
      template: template,
      onTap: (DataItem item) async {
        if (item.type == DataItemType.Data) {
          Context itemContext = widget.project.createCollectionContext(BOOK_INDEX, item).control();
          itemContext.autoReload = true;
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => BookPage(itemContext, widget.project)
          ));
          itemContext.release();
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    widget.context.release();
  }
}