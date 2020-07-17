
import 'package:flutter/material.dart';
import 'package:glib/core/array.dart';
import 'package:glib/core/core.dart';
import 'package:glib/core/gmap.dart';
import 'package:glib/main/models.dart';
import 'package:glib/main/project.dart';
import 'package:glib/utils/git_repository.dart';
import 'package:kinoko/book_list.dart';
import 'package:glib/main/context.dart';
import 'widgets/home_widget.dart';
import './configs.dart';

class CollectionsPage extends HomeWidget {
  @override
  State<StatefulWidget> createState() {
    return _CollectionsPageState();
  }
}

class _CollectionsPageState extends State<CollectionsPage> {

  Project project;
  List<Context> contexts = new List();

  Widget missBuild(BuildContext context) {
    return Container(
      child: Text("No Project"),
      alignment: Alignment.center,
    );
  }

  freeContexts() {
    for (int i = 0, t = contexts.length; i < t; ++i) {
      contexts[i].release();
    }
    contexts.clear();
  }

  Widget defaultBuild(BuildContext context) {
    Array arr = project.categories.control();
    List<Widget> tabs = [];
    List<Widget> bodies = [];
    freeContexts();
    for (int i = 0, t = arr.length; i < t; ++i) {
      GMap category = arr[i];
      String title = category["title"];
      if (title == null) title = "";
      tabs.add(Tab(text: title,));
      var ctx = project.createIndexContext(category).control();
      contexts.add(ctx);
      bodies.add(BookListPage(ctx, i));
    }
    return DefaultTabController(
      length: arr.length,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: TabBar(
            tabs: tabs,
            isScrollable: true,
          ),
        ),
        body: TabBarView(
          children: bodies
        ),
      ),
    );
  }

  @override
  void initState() {
    project = Project.getMainProject();
    if (project != null) {
      project.control();
    }
    super.initState();
  }

  @override
  void dispose() {
    freeContexts();
    r(project);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return (project != null && project.isValidated) ? defaultBuild(context) : missBuild(context);
  }
}