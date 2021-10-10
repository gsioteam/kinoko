
import 'package:flutter/material.dart';
import 'package:glib/core/array.dart';
import 'package:glib/core/core.dart';
import 'package:glib/core/gmap.dart';
import 'package:glib/main/models.dart';
import 'package:glib/main/project.dart';
import 'package:glib/utils/git_repository.dart';
import 'package:kinoko/book_list.dart';
import 'package:glib/main/context.dart';
import 'package:kinoko/libraries_page.dart';
import 'package:kinoko/search_page.dart';
import 'package:kinoko/settings_page.dart';
import 'package:kinoko/utils/image_provider.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'localizations/localizations.dart';
import './configs.dart';
import 'widgets/no_data.dart';

const double _LogoSize = 24;

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

class CollectionsPage extends StatefulWidget {
  CollectionsPage({Key key}) :
        super(key: key);

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

  final GlobalKey searchKey = GlobalKey();

  @override
  List<Widget> buildActions(BuildContext context) {
    List<Widget> actions = [];

    String settings = project?.settingsPath;
    if (settings != null && settings.isNotEmpty) {
      actions.add(
          IconButton(
              icon: Icon(Icons.settings),
              onPressed: () async {
                Context ctx = project.createSettingsContext().control();
                await Navigator.of(context).push(MaterialPageRoute(builder: (_)=>SettingsPage(ctx)));
                ctx.release();
              }
          )
      );
    }

    String search = project?.search;
    if (search != null && search.isNotEmpty) {
      actions.add(
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
      );
    }
    return actions;
  }

  Widget missBuild(BuildContext context) {
    TextStyle textStyle = TextStyle(
        fontFamily: 'DancingScript',
        fontSize: 24,
        color: Theme.of(context).disabledColor,
        shadows: [
          Shadow(
              color: Theme.of(context).colorScheme.surface,
              offset: Offset(1, 1)
          ),
        ]
    );
    return Scaffold(
      appBar: AppBar(
        title: buildLogo(context),
        actions: buildActions(context),
      ),
      body: Stack(
        children: [
          NoData(),
          Positioned(
            left: 18,
            top: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: DecoratedIcon(
                    Icons.arrow_upward,
                    color: Theme.of(context).disabledColor,
                    size: 16,
                    shadows: [
                      BoxShadow(
                          color: Theme.of(context).colorScheme.surface,
                          offset: Offset(1, 1)
                      ),
                    ]
                  ),
                ),
                Text(
                  kt('click_to_select'),
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).disabledColor,
                      shadows: [
                        Shadow(
                            color: Theme.of(context).colorScheme.surface,
                            offset: Offset(1, 1)
                        ),
                      ]
                  ),
                )
              ],
            )
          ),
        ],
      ),
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
      tabs.add(Container(
        child: Tab( text: data.title, ),
        height: 36,
      ));
      bodies.add(BookListPage(
        key: ValueKey(data),
        project: project,
        context: data.context,
      ));
    }
    return DefaultTabController(
      length: contexts.length,
      child: Scaffold(
        appBar: AppBar(
          title: buildLogo(context),
          actions: buildActions(context),
          bottom: tabs.length > 0 ? PreferredSize(
            preferredSize: new Size(double.infinity, 36.0),
            child: TabBar(
              tabs: tabs,
              isScrollable: true,
            ),
          ) : null,
          automaticallyImplyLeading: false,
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
    _setupProject();
    super.initState();
  }

  @override
  void dispose() {
    freeContexts();
    project?.release();
    super.dispose();
  }

  void _setupProject() {
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
  }

  @override
  Widget build(BuildContext context) {
    return (project != null && project.isValidated) ? defaultBuild(context) : missBuild(context);
  }

  Widget buildLogo(BuildContext context) {
    return InkWell(
      highlightColor: Theme.of(context).appBarTheme.backgroundColor,
      child: Container(
        height: 36,
        child: Row(
          children: [
            CircleAvatar(
              radius: _LogoSize / 2,
              backgroundColor: Theme.of(context).colorScheme.background,
              child: ClipOval(
                child: project == null ?
                Icon(
                  Icons.extension,
                  size: _LogoSize * 0.66,
                  color: Theme.of(context).colorScheme.onBackground,
                ) :
                Image(
                  width: _LogoSize,
                  height: _LogoSize,
                  image: projectImageProvider(project),
                  fit: BoxFit.contain,
                  errorBuilder: (context, e, stack) {
                    return Container(
                      width: _LogoSize,
                      height: _LogoSize,
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Theme.of(context).colorScheme.onBackground,
                          size: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                child: Text(project?.name ?? kt('select_project')),
              ),
            ),
          ],
        ),
      ),
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return LibrariesPage();
        }));
        var nProject = Project.getMainProject();
        if (project?.url != nProject?.url) {
          freeContexts();
          project = nProject;
          _setupProject();
          setState(() { });
        }
      },
    );
  }
}