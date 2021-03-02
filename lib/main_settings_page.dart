
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glib/main/models.dart';
import 'package:kinoko/configs.dart';
import 'package:kinoko/utils/cached_picture_image.dart';
import 'package:kinoko/utils/download_manager.dart';
import 'package:kinoko/widgets/credits_dialog.dart';
import 'package:kinoko/widgets/home_widget.dart';
import 'localizations/localizations.dart';
import 'progress_dialog.dart';
import 'widgets/settings_list.dart';

class MainSettingsPage extends HomeWidget {
  MainSettingsPage() : super(title: "settings");

  @override
  State<StatefulWidget> createState() => _MainSettingsPageState();
}

class ClearProgressItem extends ProgressItem {

  Future<void> Function() action;

  ClearProgressItem({
    this.action
  }) {
    cancelable = false;
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

class _MainSettingsPageState extends State<MainSettingsPage> {

  SizeResult size;

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
    Locale locale = Localizations.localeOf(context);
    String localeValue = "en";
    KinokoLocalizationsDelegate.supports.forEach((key, value) {
      if (locale == value) {
        localeValue = key;
      }
    });
    return SettingsList(
      items: [
        SettingItem(
            SettingItemType.Header, 
            kt("general")
        ),
        SettingItem(
          SettingItemType.Options,
          kt("language"),
          value: localeValue,
          data: [
            OptionItem("English", "en"),
            OptionItem("中文(繁體)", "zh-hant"),
            OptionItem("中文(简体)", "zh-hans"),
          ],
          onChange: (value) {
            KeyValue.set(language_key, value);
            LocaleChangedNotification(KinokoLocalizationsDelegate.supports[value]).dispatch(context);
          }
        ),
        SettingItem(
          SettingItemType.Button,
          kt("cached_size"),
          value: size == null ? "..." : _sizeString(size.other),
          data: () async {
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
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProgressDialog(title: "", item: ClearProgressItem(
                action: () async {
                  Set<String> cached = Set();
                  for (var item in DownloadManager().items) {
                    cached.add(item.cacheKey);
                  }
                  await PictureCacheManager.clearCache(without: cached);
                  await fetchSize();
                }
              ),)));
            }
          }
        ),
        SettingItem(
            SettingItemType.Label,
            kt("download_size"),
            value: size == null ? "..." : _sizeString(size.cached)
        ),
        SettingItem(
          SettingItemType.Button,
          kt("disclaimer"),
          value: "",
          data: () {
            showCreditsDialog(context);
          }
        )
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    fetchSize();
  }

  Future<void> fetchSize() async {
    Set<String> cached = Set();
    for (var item in DownloadManager().items) {
      cached.add(item.cacheKey);
    }
    SizeResult size = await PictureCacheManager.calculateCacheSize(
        cached: cached
    );
    setState(() {
      this.size = size;
    });
  }
}