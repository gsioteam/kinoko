
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/main/models.dart';
import 'package:glib/utils/git_repository.dart';
import 'package:kinoko/configs.dart';
import 'package:kinoko/utils/download_manager.dart';
import 'package:kinoko/utils/neo_cache_manager.dart';
import 'package:kinoko/widgets/credits_dialog.dart';
import 'package:kinoko/widgets/list_header.dart';
import 'package:url_launcher/url_launcher.dart';
import 'localizations/localizations.dart';
import 'progress_dialog.dart';
import 'widgets/settings_list.dart';
import 'package:get_version/get_version.dart';

class SettingCell extends StatelessWidget {

  final Widget title;
  final Widget subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  SettingCell({
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {Widget widget;
      if (subtitle != null || trailing != null) {
        List<Widget> children = [];
        if (subtitle != null) {
          children.add(Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: DefaultTextStyle(
                style: TextStyle(
                    color: theme.disabledColor
                ),
                child: subtitle,
              ),
            ),
          ));
        }
        if (trailing != null) {
          children.add(Padding(
            padding: EdgeInsets.only(left: 10),
            child: trailing,
          ));
        }
        widget = Container(
          width: constraints.maxWidth / 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: children,
          ),
        );
      }

      return ListTile(
        tileColor: theme.colorScheme.surface,
        title: title,
        trailing: widget,
        onTap: onTap,
      );
      }
    );


  }
}

class MainSettingsList extends StatelessWidget {

  final Widget title;
  final List<Widget> children;

  MainSettingsList({
    Key key,
    this.title,
    this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title,
      ),
      body: ListView(
        children: [
          ListHeader(),
          ...children,
          ListHeader(),
        ],
      ),
    );
  }
}

class MainSettingsPage extends StatefulWidget {
  MainSettingsPage({Key key}) : super(key: key,);

  @override
  State<StatefulWidget> createState() => _MainSettingsPageState();
}

class ClearProgressItem extends ProgressItem {

  Future<void> Function() action;


  ClearProgressItem({
    String text,
    this.action
  }) {
    cancelable = false;
    this.defaultText = text;
    run();
  }

  void run() async {
    await action();
    complete();
  }

  @override
  void cancel() {
  }
  
}

const Map<String, String> _languageMap = {
  'en': 'English',
  'zh-hant': '中文(繁體)',
  'zh-hans': '中文(简体)',
  'es': 'Español',
  'ru': 'русский',
  'de': 'Deutsch',
  'it': 'Italiano',
};

class _MainSettingsPageState extends State<MainSettingsPage> {

  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    String localeValue = "en";
    KinokoLocalizationsDelegate.supports.forEach((key, value) {
      if (locale == value) {
        localeValue = key;
      }
    });

    return MainSettingsList(
      title: Text(kt('settings')),
      children: [
        SettingCell(
          title: Text(kt('framework_version')),
          subtitle: Text(kt('version') + env_repo.localID()),
          trailing: Icon(Icons.refresh),
          onTap: () async {
            await showDialog(context: context, builder: (context) {
              return ProgressDialog(
                title: kt('loading'),
                item: ClearProgressItem(
                  text: kt('fetch_framework'),
                  action: () async {
                    await startFetch();
                  },
                ),
              );
            });
          },
        ),
        SettingCell(
          title: Text(kt('language')),
          subtitle: Text(_languageMap[localeValue]),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () async {
            List<PickerItem<String>> items = [];
            KinokoLocalizationsDelegate.supports.forEach((key, value) {
              items.add(PickerItem<String>(
                text: Text(_languageMap[key]),
                value: key,
              ));
            });
            items.sort((item1, item2) {
              return item1.value.compareTo(item2.value);
            });
            int index = 0;
            for (int i = 0, t = items.length; i < t; ++i) {
              if (localeValue == items[i].value) {
                index = i;
                break;
              }
            }

            String result;
            await Picker(
              adapter: PickerDataAdapter<String>(
                data: items,
              ),
              selecteds: [index],
              onConfirm: (picker, list) {
                result = items[list[0]].value;
              }
            ).showDialog(context);
            if (result != null) {
              KeyValue.set(language_key, result);
              LocaleChangedNotification(KinokoLocalizationsDelegate.supports[result]).dispatch(context);
            }
          },
        ),
        SettingCell(
          title: Text(kt('cache_manager')),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
                CacheManager()));
          },
        ),
        ListHeader(),
        SettingCell(
          title: Text(kt('disclaimer')),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            showCreditsDialog(context);
          },
        ),
        SettingCell(
          title: Text(kt('about')),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () async {
            var theme = Theme.of(context);
            showAboutDialog(
              context: context,
              applicationName: await GetVersion.appName,
              applicationVersion: await GetVersion.projectVersion,
              applicationIcon: Image.asset(
                'assets/icon.png',
                width: 32,
                height: 32,
              ),
              applicationLegalese: "© gsioteam 2021",
              children: [
                Padding(padding: EdgeInsets.only(top: 10)),
                Text.rich(
                  TextSpan(
                      children: [
                        TextSpan(
                          text: kt('about_description'),
                        ),
                        TextSpan(
                            text: project_link,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                await launch(project_link);
                              },
                            style: TextStyle(
                              color: theme.primaryColor,
                              decoration: TextDecoration.underline,
                            )
                        ),
                        TextSpan(
                          text: kt('about_description_end'),
                        )
                      ]
                  ),
                  textAlign: TextAlign.center,
                ),
              ]
            );
          },
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(kt('settings')),
      ),
      body: ListView(
        children: [
          ListHeader(),

        ],
      ),
      // SettingsList(
      //   items: [
      //     SettingItem(
      //         SettingItemType.Header,
      //         kt("general")
      //     ),
      //     SettingItem(
      //         SettingItemType.Options,
      //         kt("language"),
      //         value: localeValue,
      //         data: [
      //           OptionItem("English", "en"),
      //           OptionItem("中文(繁體)", "zh-hant"),
      //           OptionItem("中文(简体)", "zh-hans"),
      //           OptionItem("Español", "es"),
      //           OptionItem("русский", "ru"),
      //           OptionItem("Deutsch", "de"),
      //           OptionItem("Italiano", "it"),
      //         ],
      //         onChange: (value) {
      //           KeyValue.set(language_key, value);
      //           LocaleChangedNotification(KinokoLocalizationsDelegate.supports[value]).dispatch(context);
      //         }
      //     ),
      //     SettingItem(
      //         SettingItemType.Button,
      //         kt("cached_size"),
      //         value: size == null ? "..." : _sizeString(size.other),
      //         data: () async {
      //           bool result = await showDialog<bool>(
      //               context: context,
      //               builder: (context) {
      //                 return AlertDialog(
      //                   title: Text(kt("confirm")),
      //                   content: Text(kt("clear_cache")),
      //                   actions: [
      //                     TextButton(
      //                       child: Text(kt("no")),
      //                       onPressed: ()=> Navigator.of(context).pop(false),
      //                     ),
      //                     TextButton(
      //                       child: Text(kt("yes")),
      //                       onPressed:()=> Navigator.of(context).pop(true),
      //                     ),
      //                   ],
      //                 );
      //               }
      //           );
      //           if (result == true) {
      //             Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProgressDialog(title: "", item: ClearProgressItem(
      //                 action: () async {
      //                   Set<String> cached = Set();
      //                   for (var item in DownloadManager().items) {
      //                     cached.add(item.cacheKey);
      //                   }
      //                   await NeoCacheManager.clearCache(without: cached);
      //                   await fetchSize();
      //                 }
      //             ),)));
      //           }
      //         }
      //     ),
      //     SettingItem(
      //         SettingItemType.Label,
      //         kt("download_size"),
      //         value: size == null ? "..." : _sizeString(size.cached)
      //     ),
      //     SettingItem(
      //         SettingItemType.Button,
      //         kt("disclaimer"),
      //         value: "",
      //         data: () {
      //           showCreditsDialog(context);
      //         }
      //     )
      //   ],
      // ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  void dispose() {
    super.dispose();
  }

  bool isFetch = false;
  Future<void> startFetch() async {
    if (isFetch) return;
    isFetch = true;
    GitRepository repo = env_repo;
    GitAction action = repo.fetch();
    action.control();
    Completer<bool> completer = Completer();
    action.setOnComplete(() async {
      action.release();
      if (action.hasError()) {
        Fluttertoast.showToast(
          msg: action.getError(),
        );
      } else {
        if (repo.localID() != repo.highID()) {
          await startCheckout();
        }
      }
      isFetch = false;
      completer.complete();
    });
    return completer.future;
  }

  Future<void> startCheckout() async {
    GitRepository repo = env_repo;
    GitAction action = repo.checkout();
    action.control();
    action.setOnComplete(() {
      action.release();
      if (action.hasError()) {
        String err = action.getError();
        Fluttertoast.showToast(
          msg: err,
          toastLength: Toast.LENGTH_SHORT,
        );
      }
      setState(() { });
    });
  }
}

class CacheManager extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => CacheManagerState();

}

class CacheManagerState extends State<CacheManager> {

  SizeResult size;
  bool _disposed = false;

  String _sizeString(int size) {
    String unit = "KB";
    double num = size / 1024;
    if (num > 1024) {
      unit = "MB";
      num /= 1024;
    }
    return "${num.toStringAsFixed(2)} $unit";
  }

  @override
  Widget build(BuildContext context) {
    return MainSettingsList(
      title: Text(kt('cache_manager')),
      children: [
        SettingCell(
          title: Text(kt("cached_size")),
          subtitle: Text(size == null ? "..." : _sizeString(size.other),),
          trailing: size == null ? null : Icon(Icons.clear),
          onTap: size == null ? null : () async {
            bool result = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(kt("confirm")),
                    content: Text(kt("clear_cache")),
                    actions: [
                      TextButton(
                        child: Text(kt("no")),
                        onPressed: ()=> Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: Text(kt("yes")),
                        onPressed:()=> Navigator.of(context).pop(true),
                      ),
                    ],
                  );
                }
            );
            if (result == true) {
              await showDialog(context: context, builder: (context) {
                return ProgressDialog(
                  title: kt('loading'),
                  item: ClearProgressItem(
                    text: '${kt('clear')}...',
                      action: () async {
                        Set<String> cached = Set();
                        for (var item in DownloadManager().items) {
                          cached.add(item.cacheKey);
                        }
                        await NeoCacheManager.clearCache(without: cached);
                        await fetchSize();
                      }
                  ),
                );
              });
            }
          },
        ),
        SettingCell(
          title: Text(kt("download_size")),
          subtitle: Text(size == null ? "..." : _sizeString(size.cached)),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    fetchSize();
  }

  @override
  void dispose() {
    super.dispose();

    _disposed = true;
  }

  Future<void> fetchSize() async {
    Set<String> cached = Set();
    for (var item in DownloadManager().items) {
      cached.add(item.cacheKey);
    }
    SizeResult size = await NeoCacheManager.calculateCacheSize(
        cached: cached
    );
    if (!_disposed) {
      setState(() {
        this.size = size;
      });
    }
  }
}