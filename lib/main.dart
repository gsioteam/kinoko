import 'dart:io';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
// import 'package:firebase_core/firebase_core.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glib/main/models.dart';
import 'package:glib/main/project.dart';
import 'package:kinoko/favorites_page.dart';
import 'package:kinoko/history_page.dart';
import 'package:kinoko/main_settings_page.dart';
import 'package:kinoko/utils/image_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kinoko/widgets/credits_dialog.dart';
import 'collections_page.dart';
import 'configs.dart';
import 'libraries_page.dart';

import 'package:path_provider/path_provider.dart' as platform;
import 'package:glib/glib.dart';
import 'package:glib/utils/git_repository.dart';
import 'progress_dialog.dart';
import 'utils/download_manager.dart';
import 'utils/favorites_manager.dart';
import 'utils/neo_cache_manager.dart';
import 'utils/progress_items.dart';
import 'localizations/localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'widgets/better_refresh_indicator.dart';
import 'favorites_page.dart';
import 'download_page.dart';
import 'package:xml_layout/types/colors.dart' as colors;
import 'package:xml_layout/types/icons.dart' as icons;
import 'layout/layout.xml_layout.dart' as layout;
import 'package:xml_layout/xml_layout.dart';
import 'package:glib/utils/platform.dart' as glib;
import 'themes/them_desc.dart';
import 'widgets/hint_point.dart';
import 'widgets/oval_clipper.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  Locale locale;

  @override
  Widget build(BuildContext context) {
    var theme = themes[0].data;
    return NotificationListener<LocaleChangedNotification>(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          systemNavigationBarColor: theme.colorScheme.onBackground,
          systemNavigationBarDividerColor: theme.colorScheme.onBackground,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: [
            const KinokoLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: locale,
          supportedLocales: KinokoLocalizationsDelegate.supports.values,
          title: 'Kinoko',
          theme: theme,
          home: SplashScreen(),
        ),
      ),
      onNotification: (n) {
        setState(() {
          locale = n.locale;
        });
        return true;
      },
    );
  }

  @override
  void initState() {
    super.initState();

    glib.Platform.onGetLanguage = () {
      if (locale?.scriptCode != null) {
        return "${locale.languageCode}-${locale.scriptCode}";
      } else {
        return locale?.languageCode;
      }
    };
  }
}

class _LifecycleEventHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      Glib.destroy();
    }
  }
}

class ListType<T> {
  List<T> children(NodeData node) {
    return node.children<T>();
  }
}

ListType _defaultType = ListType();

Map<String, ListType> listTypes = {
  "PopupMenuEntry": ListType<PopupMenuEntry>(),
  "Color": ListType<Color>(),
};

class SplashScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return SplashScreenState();
  }
}

class SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Image(
          image: AssetImage("assets/logo.png"),
          width: 160,
          height: 60,
        ),
      ),
    );
  }

  Future<void> _loadTemplates() async {
    Future<void> load(String key) async {
      cachedTemplates[key] = await rootBundle.loadString(key);
    }
    await load("assets/collection.xml");
  }

  Future<void> _v2Setup(String path) async {
    String val = KeyValue.get(v2_key);
    if (val != 'true') {
      Directory dir = Directory(path + "/repo");
      if (await dir.exists()) {
        var ret = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: Text(kt("v2_title")),
              content: Text(kt("v2_content")),
              actions: [
                TextButton(
                  child: Text(kt("yes")),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
                TextButton(
                  child: Text(kt("no")),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                )
              ],
            );
          }
        );
        if (ret == true) {
          await dir.delete(recursive: true);
          Directory directory = await platform.getTemporaryDirectory();
          Directory picDir = Directory("${directory.path}/pic");
          if (await picDir.exists())
            await picDir.delete(recursive: true);
          DownloadManager.reloadAll();
        } else {
          SystemNavigator.pop();
          return;
        }
      }
      KeyValue.set(v2_key, 'true');
    }
  }

  Future<void> setup(BuildContext context) async {
    Directory dir = await platform.getApplicationSupportDirectory();
    share_cache["root_path"] = dir.path;

    await _loadTemplates();

    await Glib.setup(dir.path);
    Locale locale = KinokoLocalizationsDelegate.supports[KeyValue.get(language_key)];
    if (locale != null) {
      LocaleChangedNotification(locale).dispatch(context);
    }
    await _v2Setup(dir.path);
    await showDisclaimer(context);
    await fetchEnv(context);
    WidgetsBinding.instance.addObserver(_LifecycleEventHandler());
    colors.register();
    icons.register();
    layout.register();
    XmlLayout.register("CachedNetworkImageProvider", (node, key) {
      return NeoImageProvider(
        uri: Uri.parse(node.text),
        cacheManager: NeoCacheManager.defaultManager
      );
    });
    XmlLayout.register("FlatButton", (node, key) {
      return FlatButton(
        key: key,
        onPressed: node.s<VoidCallback>("onPressed"),
        child: node.child<Widget>(),
        padding: EdgeInsets.zero,
      );
    });
    XmlLayout.register("BetterRefreshIndicator", (node, key) {
      return BetterRefreshIndicator(
        child: node.child<Widget>(),
        displacement: node.s<double>("displacement", 40),
        color: node.s<Color>("color"),
        backgroundColor: node.s<Color>("backgroundColor"),
        notificationPredicate: node.s<ScrollNotificationPredicate>("notificationPredicate", defaultScrollNotificationPredicate),
        semanticsLabel: node.s<String>("semanticsLabel"),
        semanticsValue: node.s<String>("semanticsValue"),
        strokeWidth: node.s<double>("strokeWidth", 2),
        controller: node.s<BetterRefreshIndicatorController>("controller"),
      );
    });
    XmlLayout.register("Padding", (node, key) {
      return Padding(
        key: key,
        padding: node.s<EdgeInsets>("padding"),
        child: node.child<Widget>(),
      );
    });
    XmlLayout.registerInline(EdgeInsets, "only", false, (node, method) {
      return EdgeInsets.only(
        left: method[0]?.toDouble() ?? 0,
        top: method[1]?.toDouble() ?? 0,
        right: method[2]?.toDouble() ?? 0,
        bottom: method[3]?.toDouble() ?? 0,
      );
    });
    XmlLayout.registerInline(EdgeInsets, "all", false, (node, method) {
      return EdgeInsets.all(method[0]?.toDouble() ?? 0);
    });
    XmlLayout.registerInline(Color, "rgb", false, (node, method) {
      return Color.fromRGBO(method[0]?.toInt(), method[1]?.toInt(),
          method[2]?.toInt(), 1);
    });
    XmlLayout.registerInline(BorderRadius, "horizontal", false, (node, method) {
      return BorderRadius.horizontal(
        left: node.v<Radius>(method[0], Radius.zero),
        right: node.v<Radius>(method[1], Radius.zero),
      );
    });
    XmlLayout.registerFunctionReturn<List<PopupMenuEntry>>("MenuItemList");
    XmlLayout.register("List", (node, key) {
      ListType listType = listTypes[node.s<String>("type")] ?? _defaultType;
      return listType.children(node);
    });
  }

  Future<void> fetchEnv(BuildContext context) async {
    env_repo = GitRepository.allocate("env");
    if (!env_repo.isOpen()) {
      GitItem item = GitItem.clone(env_repo, env_git_url);
      item.cancelable = false;
      ProgressResult result = await showDialog<ProgressResult>(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return ProgressDialog(
              title: kt(""),
              item: item,
            );
          }
      );
      if (result != ProgressResult.Success) {
        throw Exception("WTF?!");
      }
    } else {
    }
  }

  Future<void> showDisclaimer(BuildContext context) async {
    String key = KeyValue.get(disclaimer_key);
    if (key != "true") {
      bool result = await showCreditsDialog(context);
      if (result == true) {
        KeyValue.set(disclaimer_key, "true");
      } else {
        SystemNavigator.pop();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Future<void> future = setup(context);
    future.then((value) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
          settings: RouteSettings(name: home_page_name),
          builder: (BuildContext context)=>HomePage()
      ), (route) => route.isCurrent);
    });
  }
}

class HomeDrawer extends StatefulWidget {
  final _HomePageState homeState;

  HomeDrawer(this.homeState);

  @override
  State<StatefulWidget> createState() {
    return _HomeDrawerState();
  }
}

class _HomeDrawerState extends State<HomeDrawer> with SingleTickerProviderStateMixin {

  AnimationController animationController;
  bool isFetch = false;
  bool isCheckout = false;
  bool isDispose = false;

  void startFetch() {
    if (isFetch) return;
    isFetch = true;
    animationController.repeat();
    GitRepository repo = env_repo;
    GitAction action = repo.fetch();
    action.control();
    action.setOnComplete(() {
      action.release();
      if (isDispose) return;
      this.setState(() {
        if (this.onRefresh != null) this.onRefresh();
        animationController.stop();
        animationController.reset();
        isFetch = false;
      });
      if (action.hasError()) {
        Fluttertoast.showToast(
          msg: action.getError(),
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    });
  }

  void startCheckout() {
    if (isCheckout) return;
    isCheckout = true;
    GitRepository repo = env_repo;
    GitAction action = repo.checkout();
    action.control();
    action.setOnComplete(() {
      action.release();
      if (isDispose) return;
      this.setState(() {
        if (this.onRefresh != null) this.onRefresh();
        isCheckout = false;
      });
      if (action.hasError()) {
        String err = action.getError();
        Fluttertoast.showToast(
          msg: err,
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    widget.homeState.onRefresh = onRefresh;
    widget.homeState.onFetch = startFetch;
    animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
  }

  @override
  void didUpdateWidget(HomeDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.homeState.onRefresh = null;
    oldWidget.homeState.onFetch = null;
    widget.homeState.onRefresh = onRefresh;
    widget.homeState.onFetch = startFetch;
  }

  @override
  void dispose() {
    widget.homeState.onRefresh = null;
    widget.homeState.onFetch = null;
    animationController.dispose();
    isDispose = true;
    super.dispose();
  }


  List<Widget> buildList(Project project) {
    var lv = env_repo.localID(), hv = env_repo.highID();
//    GitLibrary library = GitLibrary.findLibrary(env_repo);

    return [
      Padding(
        padding: EdgeInsets.only(top: 5, bottom: 5),
        child: Row(
          children: [
            ClipOval(
              child: Container(
                color: Colors.blueAccent,
                child: Image(
                  image: projectImageProvider(project),
                  fit: BoxFit.contain,
                  width: 36,
                  height: 36,
                  errorBuilder: (context, e, stack) {
                    return Container(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    );
                  },
                ),
              ),
              clipper: OvalClipper(),
            ),
            Padding(padding: EdgeInsets.only(left: 8)),
            Text(project.name,
                style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white)
            )
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.only(top: 10, bottom: 5),
        child: Text(
          hv == lv ? "${kt("framework")}.$hv" : "${kt("framework")}.$hv ($lv)",
          style: Theme.of(context).textTheme.caption.copyWith(color: Colors.white),
        ),
      ),
      Row(
        children: <Widget>[
          IconButton(
              icon: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColorLight,
                  child: AnimatedBuilder(
                      animation: animationController,
                      child: Icon(Icons.sync, color: Theme.of(context).primaryColor,),
                      builder: (BuildContext context, Widget _widget) {
                        return Transform.rotate(
                          angle: animationController.value * -6.3,
                          child: _widget,
                        );
                      }
                  )
              ),
              onPressed: startFetch
          ),
          (lv == hv ? Container(): IconButton(
              icon: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColorLight,
                child: Icon(Icons.get_app, color: Theme.of(context).primaryColor,),
              ),
              onPressed: isCheckout ? null:startCheckout
          ))
        ],
      )
    ];
  }

  List<Widget> getChildren() {
    var project = Project.getMainProject();
    if (env_repo == null || project == null) {
      return [
        Padding(
          padding: EdgeInsets.only(top: 5, bottom: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              ClipOval(
                child: Container(
                  color: Colors.blueAccent,
                  child: Image(
                    image: NeoImageProvider(
                      uri: Uri.parse("https://www.tinygraphs.com/squares/unkown?theme=bythepool&numcolors=3&size=180&fmt=jpg"),
                      cacheManager: NeoCacheManager.defaultManager,
                    ),
                    fit: BoxFit.contain,
                    width: 36,
                    height: 36,
                  ),
                ),
                clipper: OvalClipper(),
              ),
              Padding(padding: EdgeInsets.only(left: 8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kt("no_main_project"),
                        style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white)
                    ),
                    Padding(padding: EdgeInsets.only(top: 5)),
                    Text(kt("select_main_project_first"),
                      style: Theme.of(context).textTheme.caption.copyWith(color: Colors.white),
                      softWrap: true,
                    )
                  ],
                ),
              )
            ],
          ),
        )
      ];
    } else {
      return buildList(project);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: getChildren(),
        ),
      ),
    );
  }

  void onRefresh() {
    print("onRefresh");
    this.setState(() { });
  }

}


class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selected = 0;
  HomeDrawer drawer;
  void Function() onRefresh;
  void Function() onFetch;

  bool hasMainProject() {
    return Project.getMainProject() != null;
  }

  Widget _getBody(BuildContext context) {
    switch (selected) {
      case 0: {
        return FavoritesPage(key: ValueKey(selected),);
      }
      case 1: {
        return DownloadPage(key: ValueKey(selected),);
      }
      case 2: {
        return CollectionsPage(key: ValueKey(selected),);
      }
      case 3: {
        return HistoryPage(key: ValueKey(selected),);
      }
      case 4: {
        return MainSettingsPage(key: ValueKey(selected),);
      }
      case 5: {
        return LibrariesPage(key: ValueKey(selected),);
      }
    }
    return null;
  }

  void Function() _onTap(int idx) {
    return (){
      if (idx == 0 && !hasMainProject()) {
        Fluttertoast.showToast(
          msg: kt("select_main_project_first"),
          toastLength: Toast.LENGTH_LONG
        );
        idx = 4;
      }
      if (selected != idx) {
        setState(() {
          selected = idx;
        });

        Navigator.of(context).popUntil(ModalRoute.withName(home_page_name));
      }
    };
  }

  ValueNotifier<bool> favoritesController;

  @override
  Widget build(BuildContext context) {
    Widget body = _getBody(context);

    return Scaffold(
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        type: BottomNavigationBarType.fixed,
        currentIndex: selected,
        items: [
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.favorite),
                Positioned(
                  right: -2,
                  top: -2,
                  child: HintPoint(
                    controller: favoritesController,
                  ),
                ),
              ],
            ),
            label: kt("favorites"),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_download),
            label: kt("download_list"),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: kt("manga_home"),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: kt("history"),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: kt("settings"),
          ),
        ],
        onTap: (index) {
          setState(() {
            selected = index;
          });
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (FavoritesManager().items.length > 0) {
      selected = 0;
    } else {
      selected = 2;
    }
    favoritesController = ValueNotifier(FavoritesManager().hasNew);
    FavoritesManager().onState.addListener(_favoritesUpdate);
  }

  @override
  void dispose() {
    super.dispose();
    FavoritesManager().onState.removeListener(_favoritesUpdate);
    favoritesController.dispose();
  }

  void _favoritesUpdate() {
    favoritesController.value = FavoritesManager().hasNew;
  }
}
