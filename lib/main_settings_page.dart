
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glib/main/models.dart';
import 'package:kinoko/configs.dart';
import 'package:kinoko/widgets/home_widget.dart';
import 'localizations/localizations.dart';
import 'widgets/settings_list.dart';

class MainSettingsPage extends HomeWidget {
  MainSettingsPage() : super(title: "settings");

  @override
  State<StatefulWidget> createState() => _MainSettingsPageState();
}

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
      ],
    );
  }

}