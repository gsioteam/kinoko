import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_git/flutter_git.dart';
import 'package:glib/main/models.dart';
import 'package:kinoko/pages/favorites_page.dart';
import 'package:kinoko/pages/history_page.dart';
import 'package:kinoko/pages/main_settings_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kinoko/utils/plugins_manager.dart';
import 'package:kinoko/widgets/credits_dialog.dart';
import 'pages/collections_page.dart';
import 'configs.dart';
import 'pages/libraries_page.dart';

import 'package:path_provider/path_provider.dart' as platform;
import 'package:glib/glib.dart';
import 'utils/download_manager.dart';
import 'utils/favorites_manager.dart';
import 'localizations/localizations.dart';
import 'pages/favorites_page.dart';
import 'pages/download_page.dart';
import 'themes/them_desc.dart';
import 'utils/key_value_storage.dart';
import 'utils/local_storage.dart';
import 'widgets/hint_point.dart';
import 'utils/plugin/plugin.dart';
import 'utils/plugin/assets_filesystem.dart';
import 'package:xml_layout/types/icons.dart' as icons;

class AppChangedNotification extends Notification {
}

class LocaleChangedNotification extends AppChangedNotification {
  Locale locale;
  LocaleChangedNotification(this.locale);
}

class ThemeChangedNotification extends AppChangedNotification {
  ThemeData theme;
  ThemeChangedNotification(this.theme);
}

void main() {
  runApp(MainApp());
}

class MainApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  Locale? locale;
  late ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (locale != null)
      Configs.instance.locale = locale!;
    return NotificationListener<AppChangedNotification>(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          systemNavigationBarColor: theme.bottomNavigationBarTheme.backgroundColor,
          systemNavigationBarDividerColor: theme.bottomNavigationBarTheme.backgroundColor,
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
        if (n is LocaleChangedNotification) {
          setState(() {
            locale = n.locale;
          });
        } else if (n is ThemeChangedNotification) {
          setState(() {
            theme = n.theme;
          });
        }
        return true;
      },
    );
  }

  @override
  void initState() {
    super.initState();

    theme = themes[0].data;
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
                ),
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
    } else {

    }
  }

  ThemeData? _findTheme(String title) {
    for (var theme in themes) {
      if (theme.title == title) {
        return theme.data;
      }
    }
    return themes[0].data;
  }

  Future<void> setup(BuildContext context) async {
    Directory dir = await platform.getApplicationSupportDirectory();
    share_cache["root_path"] = dir.path;

    await _loadTemplates();

    await Glib.setup(dir.path);
    Locale? locale = KinokoLocalizationsDelegate.supports[KeyValue.get(language_key)];
    if (locale != null) {
      LocaleChangedNotification(locale).dispatch(context);
    }
    ThemeData? themeData = _findTheme(KeyValue.get(theme_key));
    if (themeData != null)
      ThemeChangedNotification(themeData).dispatch(context);

    await _v2Setup(dir.path);
    await showDisclaimer(context);
    WidgetsBinding.instance?.addObserver(_LifecycleEventHandler());

    await Configs.instance.initialize(context);
    await PluginsManager.instance.ready;

    icons.register();

    File cacert = File("${dir.path}/cacert.pem");
    if (!await cacert.exists()) {
      var buf = await rootBundle.load("assets/cacert.pem");
      await cacert.writeAsBytes(buf.buffer.asUint8List());
    }
    GitRepository.setCacertPath(cacert.path);

    if (Configs.isDebug) {
      AssetsFileSystem assetsFileSystem = AssetsFileSystem(context: context, prefix: 'test_plugin/');
      await assetsFileSystem.ready;
      String id = "test";
      PluginsManager.instance.current = Plugin(id, assetsFileSystem, DataLocalStorage(id));
    }
  }

  Future<void> showDisclaimer(BuildContext context) async {
    String key = KeyValue.get(disclaimer_key);
    if (key != "true") {
      bool? result = await showCreditsDialog(context);
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

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);


  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selected = 0;
  int _oldSelected = 0;
  void Function()? onRefresh;
  void Function()? onFetch;

  bool hasMainProject() {
    return PluginsManager.instance.current != null;
  }

  Widget? _getBody(BuildContext context) {
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

  late ValueNotifier<bool> favoritesController;

  @override
  Widget build(BuildContext context) {
    Widget? body = _getBody(context);
    var size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: body,
        transitionBuilder: (child, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              int nav = 1;
              if (child != body) nav = -1;
              if (selected < _oldSelected) nav *= -1;
              return Transform.translate(
                offset: Offset(size.width * (1-animation.value) * nav, 0),
                child: child,
              );
            },
            child: child,
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
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
            label: kt("settings"),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.settings),
                // Positioned(
                //   right: -2,
                //   top: -2,
                //   child: HintPoint(
                //     controller: newEnv,
                //   ),
                // ),
              ],
            ),
          ),
        ],
        onTap: (index) {
          switchTo(index);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (FavoritesManager().items.data.length > 0) {
      _oldSelected = selected = 0;
    } else {
      _oldSelected = selected = 2;
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

  void switchTo(int index) {
    if (selected != index) {
      setState(() {
        _oldSelected = selected;
        selected = index;
      });
    }
  }

}
