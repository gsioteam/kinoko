
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:kinoko/book_list.dart';
import 'package:kinoko/widgets/better_refresh_indicator.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/project.dart';
import 'package:glib/main/context.dart';
import 'localizations/localizations.dart';

class SearchPage extends StatefulWidget {

  Project project;
  Context context;

  SearchPage(this.project, this.context);

  @override
  State<StatefulWidget> createState() {
    return _SearchPageState();
  }

}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kt("search")),
        backgroundColor: Colors.white,
        iconTheme: Theme.of(context).iconTheme.copyWith(color: Colors.black87),
      ),
      body: BookListPage(widget.project, widget.context),
    );
  }

}