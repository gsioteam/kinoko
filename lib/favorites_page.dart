

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/project.dart';
import 'configs.dart';
import 'widgets/home_widget.dart';
import 'widgets/book_item.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'localizations/localizations.dart';
import 'book_page.dart';
import 'picture_viewer.dart';

class FavoritesPage extends HomeWidget {
  @override
  String get title => "favorites";

  @override
  State<StatefulWidget> createState() {
    return _FavoritesPageState();
  }

}

class _FavoritesPageState extends State<FavoritesPage> {
  Array data;

  itemClicked(int idx) async {
    DataItem item = data[idx];
    Project project = Project.allocate(item.projectKey);
    if (!project.isValidated) {
      Fluttertoast.showToast(msg: kt("no_project_found"));
      project.release();
      return;
    }
    DataItemType type = item.type;
    Context ctx;
    if (type == DataItemType.Book) {
      ctx = project.createBookContext(item).control();
    } else if (type == DataItemType.Chapter) {
      ctx = project.createChapterContext(item).control();
    } else {
      Fluttertoast.showToast(msg: kt("can_not_determine_the_context_type"));
      project.release();
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      if (type == DataItemType.Book) {
        return BookPage(ctx, project);
      } else {
        return PictureViewer(ctx, null);
      }
    }));
    ctx.release();
    project.release();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        return makeBookItem(context, data[index], () {
          itemClicked(index);
        });
      }
    );
  }

  @override
  void initState() {
    data = DataItem.loadCollectionItems(collection_mark).control();
    super.initState();
  }

  @override
  void dispose() {
    data.release();
    super.dispose();
  }
}