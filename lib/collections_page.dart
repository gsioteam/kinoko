
import 'package:flutter/material.dart';
import 'package:glib/core/array.dart';
import 'package:glib/core/core.dart';
import 'package:glib/core/gmap.dart';
import 'package:glib/main/models.dart';
import 'package:glib/main/project.dart';
import 'package:glib/utils/git_repository.dart';
import 'package:kinoko/book_list.dart';
import 'package:glib/main/context.dart';
import 'package:kinoko/search_page.dart';
import 'widgets/home_widget.dart';
import './configs.dart';

class _RectClipper extends CustomClipper<Rect> {

  Offset center;
  double value;

  _RectClipper(this.center, this.value);

  @override
  Rect getClip(Size size) {
    double length = (center - Offset(0, size.height)).distance;
    return Rect.fromCircle(
      center: center,
      radius: length * value
    );
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return !(oldClipper is _RectClipper) || (oldClipper as _RectClipper).value != value;
  }

}

class CollectionsPage extends HomeWidget {
  CollectionsPage() : super(key: GlobalKey()) {
    this.title = "app_title";
  }

  @override
  State<StatefulWidget> createState() {
    return _CollectionsPageState();
  }

  GlobalKey searchKey = GlobalKey();

  @override
  List<Widget> buildActions(BuildContext context, void Function() changed) {
    Project project = ((key as GlobalKey).currentState as _CollectionsPageState)?.project;
    String search = project?.search;
    return (search == null || search.isEmpty) ? [] : [
      IconButton(
        key: searchKey,
        icon: Icon(Icons.search),
        onPressed: () async {
          RenderObject object = searchKey.currentContext?.findRenderObject();
          var translation = object?.getTransformTo(null)?.getTranslation();
          var size = object?.semanticBounds?.size;
          Offset center;
          if (translation != null) {
            double x = translation.x, y = translation.y;
            if (size != null) {
              x += size.width / 2;
              y += size.height / 2;
            }
            center = Offset(x, y);
          } else {
            center = Offset(0, 0);
          }

          Project project = ((key as GlobalKey)?.currentState as _CollectionsPageState)?.project;
          project?.control();
          Context ctx = project?.createSearchContext()?.control();
          await Navigator.of(context).push(PageRouteBuilder(
            pageBuilder: (context, animation, secAnimation) {
              return SearchPage(project, ctx);
            },
            transitionDuration: Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secAnimation, child) {
              return ClipOval(
                clipper: _RectClipper(center, animation.value),
                child: child,
              );
            }
          ));
          ctx?.release();
          project?.release();
        }
      )
    ];
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
      bodies.add(BookListPage(project, data.context));
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