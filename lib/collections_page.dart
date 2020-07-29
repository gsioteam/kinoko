
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
  CollectionsPage() {
    this.title = "app_title";
  }

  @override
  State<StatefulWidget> createState() {
    return _CollectionsPageState();
  }
}

class _CollectionData {
  Context context;
  String title;

  _CollectionData(this.context, this.title);
}

class _CollectionsPageState extends State<CollectionsPage> {

  Project project;
  List<_CollectionData> contexts;

  Widget missBuild(BuildContext context) {
    return Container(
      child: Text("No Project"),
      alignment: Alignment.center,
    );
  }

  freeContexts() {
    for (int i = 0, t = contexts.length; i < t; ++i) {
      contexts[i].context.release();
    }
    contexts.clear();
  }

  Widget defaultBuild(BuildContext context) {
    List<Widget> tabs = [];
    List<Widget> bodies = [];
    for (int i = 0, t = contexts.length; i < t; ++i) {
      _CollectionData data = contexts[i];
      tabs.add(Tab(text: data.title,));
      bodies.add(BookListPage(project, data.context, i));
    }
    return DefaultTabController(
      length: contexts.length,
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
    contexts = [];
    if (project != null) {
      project.control();
      Array arr = project.categories.control();
      for (int i = 0, t = arr.length; i < t; ++i) {
        GMap category = arr[i];
        String title = category["title"];
        if (title == null) title = "";
        var ctx = project.createIndexContext(category).control();
        contexts.add(_CollectionData(ctx, title));
      }
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