import 'dart:io';

import 'package:flutter/material.dart';
import 'package:glib/core/core.dart';
import 'package:kinoko/favorites_page.dart';
import 'book_list.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'collections_page.dart';
import 'configs.dart';
import 'libraries_page.dart';

import 'package:path_provider/path_provider.dart' as platform;
import 'package:glib/glib.dart';
import 'package:glib/utils/git_repository.dart';
import 'progress_dialog.dart';
import 'utils/progress_items.dart';
import 'localizations/localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'widgets/home_widget.dart';
import 'favorites_page.dart';
import 'download_page.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        const KinokoLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale.fromSubtags(languageCode: "zh"),
        const Locale.fromSubtags(languageCode: "en")
      ],
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
    );
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

class SplashScreen extends StatelessWidget {

  Future<void> setup(BuildContext context) async {
    Directory dir = await platform.getApplicationSupportDirectory();
    share_cache["root_path"] = dir.path;
    await Glib.setup(dir.path);
    await fetchEnv(context);
    WidgetsBinding.instance.addObserver(_LifecycleEventHandler());
  }

  void fetchEnv(BuildContext context) async {
    env_repo = GitRepository.allocate("env");
    if (!env_repo.isOpen()) {
      GitItem item = GitItem.clone(env_repo, env_git_url);
      item.cancelable = false;
      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return ProgressDialog(
            title: "title",
            item: item,
          );
        }
      );
    } else {

    }
  }

  @override
  Widget build(BuildContext context) {
    Future<void> future = setup(context);
    future.then((value) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
        settings: RouteSettings(name: home_page_name),
        builder: (BuildContext context)=>HomePage()
      ), (route) => route.isCurrent);
    });
    return Container(color: Colors.white,);
  }
}

class HomeDrawer extends StatefulWidget {
  _HomePageState homeState;

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

  void startFetch() {
    if (isFetch) return;
    isFetch = true;
    animationController.repeat();
    GitRepository repo = env_repo;
    GitAction action = repo.fetch();
    action.control();
    action.setOnComplete(() {
      action.release();
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
    animationController = AnimationController(
        vsync: this,
        duration: Duration(seconds: 1)
    );
//    animationController.repeat();
  }

  List<Widget> getChildren() {
    var repo = env_repo;
    var lv = repo.localID(), hv = repo.highID();
    return repo == null ? [] : [
      Padding(
        padding: EdgeInsets.only(top: 10, bottom: 5),
        child: Text.rich(
          TextSpan(
            text: "准备就绪",
            style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white),
            children: [
              TextSpan(
                text: "  (${lv})",
                style: Theme.of(context).textTheme.caption.copyWith(color: Colors.white)
              )
            ]
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(top: 10, bottom: 10),
        child: Text(
          "线上版本 ${hv}",
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

  @override
  Widget build(BuildContext context) {
    this.widget.homeState.onRefresh = onRefresh;
    widget.homeState.onFetch = startFetch;
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Colors.blue,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: getChildren(),
        ),
      ),
    );
  }

  void onRefresh() {
    this.setState(() { });
  }
}

class NavigationController {
  AppBarData appBarData;

  NavigationController(this.appBarData);

  String get title => appBarData == null ? "" : appBarData.title;

  List<Widget> buildActions(BuildContext context, void Function() reload) {
    return appBarData == null ? [] : appBarData.buildActions(context, reload);
  }
}

class NavigationBar extends StatefulWidget implements PreferredSizeWidget {

  NavigationController controller;

  NavigationBar(AppBarData appBarData) {
    controller = NavigationController(appBarData);
  }

  @override
  State<StatefulWidget> createState() => _NavigationBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _NavigationBarState extends State<NavigationBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(kt(widget.controller.title)),
      elevation: 0,
      actions: widget.controller.buildActions(context, onReload),
    );
  }

  void onReload() {
    setState(() {});
  }

}

class HomePage extends HomeWidget {
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

  HomeWidget _getBody(BuildContext context) {
    switch (selected) {
      case 0: {
        return CollectionsPage();
      }
      case 1: {
        return FavoritesPage();
      }
      case 2: {
        return DownloadPage();
      }
      case 3: {
        return LibrariesPage();
      }
    }
    return null;
  }

  void Function() _onTap(int idx) {
    return (){
      if (selected != idx) {
        setState(() {
          selected = idx;
        });

        Navigator.of(context).popUntil(ModalRoute.withName(home_page_name));
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    HomeWidget body = _getBody(context);

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            HomeDrawer(this),
            ListTile(
              selected: selected == 0,
              leading: Icon(Icons.collections_bookmark),
              title: Text(kt("manga_home")),
              onTap: _onTap(0),
            ),
            ListTile(
              selected: selected == 1,
              leading: Icon(Icons.favorite),
              title: Text(kt("favorites")),
              onTap: _onTap(1),
            ),
            ListTile(
              selected: selected == 2,
              leading: Icon(Icons.file_download),
              title: Text(kt("download_list")),
              onTap: _onTap(2),
            ),
            ListTile(
              selected: selected == 3,
              leading: Icon(Icons.account_balance),
              title: Text(kt("manage_projects")),
              onTap: _onTap(3),
            ),
          ],
        ),
      ),
      appBar: NavigationBar(body.appBarData),
      body: body,
    );
  }

}
