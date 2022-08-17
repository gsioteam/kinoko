
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_pickers/flutter_material_pickers.dart' as pickers;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/main/models.dart';
import 'package:kinoko/configs.dart';
import 'package:kinoko/utils/download_manager.dart';
import 'package:kinoko/utils/neo_cache_manager.dart';
import 'package:kinoko/utils/notice_manager.dart';
import 'package:kinoko/widgets/credits_dialog.dart';
import 'package:kinoko/widgets/list_header.dart';
import 'package:kinoko/widgets/markdown_dialog.dart';
import 'package:kinoko/widgets/navigator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localizations/localizations.dart';
import '../main.dart';
import '../widgets/progress_dialog.dart';
import 'theme_page.dart';
import '../widgets/hint_point.dart';
import '../widgets/picker_item.dart';
import '../widgets/settings_list.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingCell extends StatelessWidget {

  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

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
      builder: (context, constraints) {
        Widget? widget;
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
                  child: subtitle!,
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

  final Widget? title;
  final List<Widget> children;

  MainSettingsList({
    Key? key,
    this.title,
    this.children = const [],
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
  MainSettingsPage({Key? key}) : super(key: key,);

  @override
  State<StatefulWidget> createState() => _MainSettingsPageState();
}

class ClearProgressItem extends ProgressItem {

  Future<void> Function()? action;

  ClearProgressItem({
    required String text,
    this.action
  }) : super(ProgressValue(
    label: text
  )) {
    run();
  }

  void run() async {
    try {
      await action?.call();
      value = value.copyWith(
        status: ProgressStatus.Success,
      );
    } catch (e) {
      value = value.copyWith(
        status: ProgressStatus.Failed,
      );
    }

  }
  
}

const Map<String, String> _languageMap = {
  'en': 'English',
  'zh-hant': '中文(繁體)',
  'zh-hans': '中文(简体)',
  'es': 'Español',
  'tr': 'Türkçe',
  'pt-br': 'Portuguese - Brazil',
  'ru': 'русский',
};

class _MainSettingsPageState extends State<MainSettingsPage> {

  late ValueNotifier<bool> newNoticeListener;

  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    String localeValue = "en";
    KinokoLocalizationsDelegate.supports.forEach((key, value) {
      if (locale == value) {
        localeValue = key;
      }
    });
    String label = KeyValue.get(theme_key);
    if (label.isEmpty)
      label = "default";

    var noticeData = NoticeManager.instance().displayData();

    return MainSettingsList(
      title: Text(kt('settings')),
      children: [
        SettingCell(
          title: Text(kt('theme')),
          subtitle: Text(kt(label)),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.of(context).push(SwitchMaterialPageRoute(builder: (context) {
              return ThemePage();
            }));
          },
        ),
        SettingCell(
          title: Text(kt('language')),
          subtitle: Text(_languageMap[localeValue]!),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () async {
            PickerItem<String>? selectedItem;
            List<PickerItem<String>> items = [];
            KinokoLocalizationsDelegate.supports.forEach((key, value) {
              PickerItem<String> item = PickerItem<String>(
                _languageMap[key]!,
                key,
              );
              items.add(item);
              if (item.value == localeValue) {
                selectedItem = item;
              }
            });
            items.sort((item1, item2) {
              return item1.value.compareTo(item2.value);
            });

            var item = await pickers.showMaterialScrollPicker(
              title: kt('language'),
              context: context,
              items: items,
              selectedItem: selectedItem
            );

            if (item != null) {
              KeyValue.set(language_key, item.value);
              LocaleChangedNotification(KinokoLocalizationsDelegate.supports[item.value]!).dispatch(context);
            }
          },
        ),
        SettingCell(
          title: Text(kt('cache_manager')),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.of(context).push(SwitchMaterialPageRoute(builder: (context) =>
                CacheManager()));
          },
        ),
        SettingCell(
          title: Text(kt('ink_screen')),
          trailing: Switch(
              value: NavigatorConfig.navigatorType == NavigatorType.InkScreen,
              onChanged: (value) {
                setState(() {
                  if (value) {
                    NavigatorConfig.navigatorType = NavigatorType.InkScreen;
                  } else {
                    NavigatorConfig.navigatorType = NavigatorType.Normal;
                  }
                });
              }
          ),
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
            PackageInfo packageInfo = await PackageInfo.fromPlatform();
            showAboutDialog(
              context: context,
              applicationName: packageInfo.appName,
              applicationVersion: packageInfo.version,
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
        ListHeader(),
        if (noticeData != null)
          SettingCell(
            title: Text(noticeData.title),
            trailing: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.keyboard_arrow_right),
                Positioned(
                  right: -2,
                  top: -2,
                  child: HintPoint(
                    controller: newNoticeListener,
                  ),
                ),
              ],
            ),
            onTap: () {
              NoticeManager.instance().clearNew();
              showDialog(
                  context: context,
                  builder: (context) {
                    return MarkdownDialog(
                        uri: noticeData.uri,
                        markdown: noticeData.markdown
                    );
                  }
              );
            },
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    newNoticeListener = ValueNotifier(NoticeManager.instance().value.newContent);
    NoticeManager.instance().addListener(_noticeUpdate);
  }

  _noticeUpdate() {
    newNoticeListener.value = NoticeManager.instance().value.newContent;
  }

  void dispose() {
    super.dispose();
    NoticeManager.instance().removeListener(_noticeUpdate);
  }

}

class CacheManager extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => CacheManagerState();

}

class CacheManagerState extends State<CacheManager> {

  SizeResult? size;
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
          subtitle: Text(size == null ? "..." : _sizeString(size!.other),),
          trailing: size == null ? null : Icon(Icons.clear),
          onTap: size == null ? null : () async {
            bool? result = await showDialog<bool>(
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
                  run: () {
                    return ClearProgressItem(
                      text: '${kt('clear')}...',
                      action: () async {
                        Set<String> cached = Set();
                        for (var item in DownloadManager().items.data) {
                          cached.add(item.cacheKey);
                        }
                        await NeoCacheManager.clearCache(without: cached);
                        await fetchSize();
                      }
                    );
                  },
                );
              });
            }
          },
        ),
        SettingCell(
          title: Text(kt("download_size")),
          subtitle: Text(size == null ? "..." : _sizeString(size!.cached)),
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
    for (var item in DownloadManager().items.data) {
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