
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';

enum SettingItemType {
  Header,
  Switch,
  Options
}

typedef ValueChangedCallback = void Function(dynamic);

class OptionItem {
  String text;
  String value;

  OptionItem(this.text, this.value);
}

class SettingItem {
  SettingItemType type;
  String title;
  String subtitle;
  dynamic value;
  dynamic data;
  ValueChangedCallback onChange;

  SettingItem(this.type, this.title, {this.subtitle, this.value, this.data, this.onChange});
}

class SettingsList extends StatefulWidget {
  final List<SettingItem> items;

  SettingsList({Key key, this.items}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SettingsListState();

}

class _SettingsListState extends State<SettingsList> {

  String findOptionsName(SettingItem item, String value) {
    List<OptionItem> data = item.data;
    for (OptionItem it in data) {
      if (it.value == value) {
        return it.text;
      }
    }
    return null;
  }

  int findOptionsIndex(SettingItem item, String value) {
    List<OptionItem> data = item.data;
    for (int i = 0, t = data.length; i < t; ++i) {
      if (data[i].value == value) {
        return i;
      }
    }
    return 0;
  }

  Widget buildStyleTrailing1(SettingItem item) {
    switch (item.type) {
      case SettingItemType.Options: {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(findOptionsName(item, item.value)),
            Icon(Icons.chevron_right)
          ],
        );
      }
      case SettingItemType.Switch: {
        return Switch(
          value: item.value,
          onChanged: (value) {
            item.onChange?.call(value);
          }
        );
      }
      default: return null;
    }
  }

  Widget buildStyle1(SettingItem item, [GestureTapCallback onTap]) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(item.title),
          subtitle: item.subtitle == null ? null : Text(item.subtitle),
          trailing: buildStyleTrailing1(item),
          onTap: onTap,
        ),
        Divider(height: 1,)
      ],
    );
  }

  Future<T> pickerValue<T>(List<PickerItem<T>> data, int index) {
    Completer<T> completer = Completer();
    Picker picker = new Picker(
      adapter: PickerDataAdapter<T>(
        data: data,
      ),
      selecteds: [index],
      onConfirm: (picker, selects) {
        completer.complete(data[selects[0]].value);
      }
    );
    picker.showModal<String>(context);
    return completer.future;
  }

  Widget buildItem(SettingItem item) {
    switch (item.type) {
      case SettingItemType.Header: {
        return Container(
          padding: EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
          color: Colors.blueGrey[50],
          child: Text(item.title, style: Theme.of(context).textTheme.bodyText1.copyWith(fontWeight: FontWeight.bold),),
        );
      }
      case SettingItemType.Options: {
        return buildStyle1(item, () async {
          String newValue = await pickerValue((item.data as List<OptionItem>).map<PickerItem<String>>((e) {
            return PickerItem<String>(
                text: Text(e.text),
                value: e.value
            );
          }).toList(), findOptionsIndex(item, item.value));
          item.onChange?.call(newValue);
        });
      }
      case SettingItemType.Switch: {
        return buildStyle1(item);
      }
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: ClampingScrollPhysics(),
        itemBuilder: (context, index) {
          SettingItem item = widget.items[index];
          return buildItem(item);
        },
        itemCount: widget.items.length
    );
  }

}