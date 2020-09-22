

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/context.dart';
import 'localizations/localizations.dart';
import 'package:glib/main/setting_item.dart';
import 'widgets/settings_list.dart' as setting;

class SettingsPage extends StatefulWidget {

  final Context context;
  SettingsPage(this.context);

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Array data;

  Widget buildItem(BuildContext context, SettingItem item) {
    String name = item.name;
    switch (item.type) {
      case SettingItem.Header: {
        return Container(
          padding: EdgeInsets.fromLTRB(5, 2, 5, 2),
          height: 30,
          child: Row(
            children: <Widget>[
//              Image(
//                image: CachedNetworkImageProvider(item.picture),
//                width: 26,
//                height: 26,
//              ),
//              Padding(padding: EdgeInsets.all(5)),
              Text(item.title, style: Theme.of(context).textTheme.subtitle1.copyWith(color: Colors.indigoAccent),)
            ],
          ),
        );
      }
      case SettingItem.Switch: {
        return ListTile(
          title: Text(item.title),
          trailing: Switch(
            value: widget.context.getSetting(name) == true,
            onChanged: (bool value) {
              setState(() {
                widget.context.setSetting(name, value);
              });
            },
          ),
        );
      }
      case SettingItem.Input: {
        return ListTile(
          title: Text(item.title)
        );
      }
      case SettingItem.Options: {
        return ListTile(
          title: Text(item.title)
        );
      }
      default: return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kt("settings")),
      ),
      body: setting.SettingsList(
        items: buildItems(),
      ),
    );
  }

  List<setting.SettingItem> buildItems() {
    List<setting.SettingItem> items = <setting.SettingItem>[];
    int len = data.length;
    for (int i = 0; i < len; ++i) {
      SettingItem settingItem = data[i];
      String name = settingItem.name;
      items.add(setting.SettingItem(
        setting.SettingItemType.values[settingItem.type],
        settingItem.title,
        value: widget.context.getSetting(name),
        data: buildData(settingItem),
        onChange: (value) {
          setState(() {
            widget.context.setSetting(name, value);
          });
        }
      ));
    }
    return items;
  }

  dynamic buildData(SettingItem item) {
    switch (item.type) {
      case SettingItem.Input: {
        return item.data;
      }
      case SettingItem.Options: {
        Array arr = item.data;
        return arr?.map((element) {
          return setting.OptionItem(
            element["name"],
            element["value"]
          );
        })?.toList();
      }
      default: return null;
    }
  }

  @override
  void initState() {
    super.initState();

    widget.context.control();
    widget.context.enterView();
    data = widget.context.data.control();
  }

  @override
  void dispose() {
    super.dispose();

    widget.context.exitView();
    widget.context.release();
    data.release();
  }
}