

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/context.dart';
import 'localizations/localizations.dart';
import 'package:glib/main/setting_item.dart';

class SettingsPage extends StatefulWidget {

  Context context;
  SettingsPage(this.context);

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Array data;

  Widget buildItem(BuildContext context, SettingItem item) {
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
            value: false,
            onChanged: (bool value) {  },
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kt("settings")),
      ),
      body: ListView.separated(
          itemBuilder: (context, index) {
            SettingItem item = data[index];
            print("Title ${item.title}");
            return ListTile(
              title: Text(kt(item.title)),
            );
          },
          separatorBuilder: (context, index)=> Divider(),
          itemCount: data.length
      ),
    );
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