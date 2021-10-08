
import 'package:flutter/material.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/project.dart';
import 'package:kinoko/widgets/book_item.dart';

import 'book_list.dart';

class CollectionPage extends StatelessWidget {

  final String title;
  final Project project;
  final Context context;

  CollectionPage({this.title, this.project, this.context});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: BookListPage(
        project: project,
        context: this.context,
      ),
    );
  }
}
