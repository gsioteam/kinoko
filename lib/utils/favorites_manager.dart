
import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/collection_data.dart';
import 'package:glib/main/data_item.dart';
import 'package:kinoko/utils/book_info.dart';
import 'package:kinoko/utils/key_value_storage.dart';
import 'package:kinoko/utils/plugin/manga_loader.dart';
import 'package:kinoko/utils/plugins_manager.dart';
import '../configs.dart';
import 'plugin/plugin.dart';

const Duration _updateInterval = const Duration(minutes: 30);

class FavAttachment {
  late DateTime date;
  late String link;
  late int index;
  late String last;

  FavAttachment.fromData(dynamic data) {
    fill(data);
  }

  void fill(dynamic data) {
    date = DateTime.tryParse(data['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    link = data['value'];
    index = data['index'];
    last = data['last'];
  }

  Map toData() => {
    'date': date.toString(),
    'value': link,
    'index': index,
    'last': last,
  };
}

class LastData {
  String name;
  String key;
  DateTime updateTime;

  LastData({
    required this.name,
    required this.key,
    required this.updateTime
  });

  LastData.fromData(Map data) :
        name = data["name"],
        key = data["key"],
        updateTime = DateTime.fromMillisecondsSinceEpoch(data["update_time"] ?? 0);

  Map toData() {
    return {
      "name": name,
      "key": key,
      "update_time": updateTime.millisecondsSinceEpoch,
    };
  }
}

class FavCheckItem extends ValueNotifier<bool> {

  final FavoritesManager manager;
  final BookInfo info;
  LastData last;
  String pluginID;
  String bookPage;

  FavCheckItem.fromData(this.manager, Map data) :
        info = BookInfo.fromData(data["info"]),
        last = LastData.fromData(data["last"]),
        pluginID = data["pluginID"],
        bookPage = data["bookPage"],
        super(data["has_new"] == true);

  FavCheckItem(this.manager, this.info, {
    required this.last,
    required this.pluginID,
    required this.bookPage,
    bool hasNew = false,
  }) : super(hasNew);

  Map toData() {
    return {
      "info": info.toData(),
      "last": last.toData(),
      "has_new": value,
      "pluginID": pluginID,
      "bookPage": bookPage,
    };
  }

  // FavCheckItem(this.data, this.item) : super(false) {
  //   attachment = FavAttachment.fromData(jsonDecode(data.data));
  //   _loadData();
  // }

  void clearNew() {
    value = false;
    manager._itemUpdate(this);
  }

  Future<void> checkNew(bool first) async {
    if (!first) {
      if (last.updateTime.compareTo(DateTime.now().subtract(_updateInterval)) > 0) {
        return;
      }
    }
    Plugin? plugin = PluginsManager.instance.findPlugin(pluginID);
    if (plugin == null) return;
    Processor processor = Processor(
        plugin: plugin,
        data: info.data,
    );

    try {
      LastData lastData = await processor.checkNew();
      if (first) {
        last = lastData;
        manager._itemUpdate(this);
      } else {
        if (last.key != lastData.key) {
          last = lastData;
          value = true;
          manager._itemUpdate(this);
        }
      }
    } catch (e) {
      print(e);
    }
    processor.dispose();
  }

  bool get loading => value;
}

class FavoritesManager {
  static FavoritesManager? _instance;
  ChangeNotifier onState = ChangeNotifier();

  late KeyValueStorage<List<FavCheckItem>> items;

  factory FavoritesManager() {
    if (_instance == null) {
      _instance = FavoritesManager._();
    }
    return _instance!;
  }

  FavoritesManager._() {
    items = KeyValueStorage(
        key: "favorite_items",
        decoder: (text) {
          if (text.isNotEmpty) {
            List list = jsonDecode(text);
            List<FavCheckItem> items = [];
            for (var data in list) {
              try {
                items.add(FavCheckItem.fromData(this, data));
              } catch (e) {

              }
            }
            return items;
          } else {
            return [];
          }
        },
        encoder: (list) {
          return jsonEncode(list.map((e) => e.toData()).toList());
        }
    );
    Set<String> index = {};
    for (var item in items.data) {
      index.add(item.info.key);
    }

    Array? data = CollectionData.all(collection_mark);
    if (data != null) {
      for (int  i = 0, t = data.length; i < t; ++i) {
        CollectionData d = data[i];
        var item = DataItem.fromCollectionData(d);
        if (item != null) {
          if (!index.contains(item.link)) {
            FavAttachment attachment = FavAttachment.fromData(jsonDecode(d.data));
            items.data.add(FavCheckItem(
              this,
              BookInfo(
                  key: item.link,
                  title: item.title,
                  picture: item.picture,
                  link: item.link,
                  subtitle: item.subtitle,
                  data: {
                    "title": item.title,
                    "picture": item.picture,
                    "link": item.link,
                    "subtitle": item.subtitle,
                  }
              ),
              last: LastData(
                name: attachment.last,
                key: attachment.link,
                updateTime: attachment.date,
              ),
              pluginID: item.projectKey,
              bookPage: "book",
              hasNew: d.flag == 1,
            ));
          }
        }
      }
    }
    automaticCheckNew();
  }

  bool get hasNew {
    for (var item in items.data) {
      if (item.value) return true;
    }
    return false;
  }

  bool add(Plugin plugin, BookInfo bookInfo, String bookPage, [LastData? lastData]) {
    for (var item in items.data) {
      if (item.info.key == bookInfo.key) {
        return false;
      }
    }
    if (bookPage[0] != '/')
      bookPage = "/$bookPage";
    var item = FavCheckItem(
      this,
      bookInfo,
      last: lastData??LastData(
        name: "...",
        key: "",
        updateTime: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      pluginID: plugin.id,
      bookPage: bookPage,
    );
    items.data.add(item);
    items.update();
    if (lastData == null)
      item.checkNew(true);
    return true;
  }

  void remove(String key) {
    for (int i = 0, t = items.data.length; i < t; ++i) {
      var item = items.data[i];
      if (item.info.key == key) {
        items.data.removeAt(i);
        items.update();
        return;
      }
    }
  }

  bool exist(String key) {
    for (int i = 0, t = items.data.length; i < t; ++i) {
      var item = items.data[i];
      if (item.info.key == key) {
        return true;
      }
    }
    return false;
  }

  void automaticCheckNew() async {
    for (int i = 0, t = items.data.length; i < t; ++i) {
      FavCheckItem checkItem = items.data[i];
      try {
        await checkItem.checkNew(false);
      } catch (e) {
        print("Check new failed $e");
      }
    }
    Future.delayed(Duration(minutes: 20), automaticCheckNew);
  }

  bool isFavorite(String key) {
    for (int i = 0, t = items.data.length; i < t; ++i) {
      var item = items.data[i];
      if (item.info.key == key) return true;
    }
    return false;
  }

  void _itemUpdate(FavCheckItem item) {
    if (items.data.contains(item)) {
      items.update();
    }
  }

  void reorder() {
    items.update();
  }

  void clearNew(String key) {
    for (int i = 0, t = items.data.length; i < t; ++i) {
      var item = items.data[i];
      if (item.info.key == key) {
        item.clearNew();
        return;
      }
    }
  }
}