
import 'dart:convert';

import 'package:glib/core/array.dart';
import 'package:glib/core/gmap.dart';
import 'package:glib/main/collection_data.dart';
import 'package:glib/main/data_item.dart';
import 'package:kinoko/utils/book_info.dart';
import 'package:kinoko/utils/key_value_storage.dart';
import '../configs.dart';
import 'plugin/plugin.dart';

const int _MaxHistories = 200;

class HistoryItem {
  final HistoryManager manager;
  BookInfo info;
  String pluginID;
  DateTime date;
  String bookPage;

  HistoryItem(this.manager, {
    required this.info,
    required this.pluginID,
    required this.date,
    required this.bookPage,
  });

  HistoryItem.fromData(this.manager, Map data) :
        info = BookInfo.fromData(data["info"]),
        pluginID = data["pluginID"],
        date = DateTime.fromMillisecondsSinceEpoch(data["date"]??0),
        bookPage = data["bookPage"];

  Map toData() {
    return {
      "info": info.toData(),
      "pluginID": pluginID,
      "date": date.millisecondsSinceEpoch,
      "bookPage": bookPage,
    };
  }
}

class HistoryManager {
  static HistoryManager? _instance;
  late KeyValueStorage<List<HistoryItem>> items;

  factory HistoryManager() {
    if (_instance == null) {
      _instance = HistoryManager._();
    }
    return _instance!;
  }

  HistoryManager._() {
    items = KeyValueStorage<List<HistoryItem>>(
      key: "history_items",
      decoder: (text) {
        List<HistoryItem> list = [];
        try {
          if (text.isNotEmpty) {
            var json = jsonDecode(text);
            for (var data in json) {
              list.add(HistoryItem.fromData(this, data));
            }
          }
        } catch (e) {
          print("Error when parse history_items $e");
        }
        return list;
      },
      encoder: (list) {
        return jsonEncode(list.map((e) => e.toData()).toList());
      }
    );
  }

  static const int ITEM_COUNT = 60;

  void clear() {
    items.data.clear();
    items.update();
  }

  void insert(BookInfo bookInfo, String bookPage, Plugin plugin) {
    for (int i = 0, t = items.data.length; i < t; ++i) {
      var item  = items.data[i];
      if (item.info.key == bookInfo.key) {
        items.data.removeAt(i);
        break;
      }
    }
    if (bookPage[0] != '/')
      bookPage = "/$bookPage";
    items.data.insert(0, HistoryItem(this,
      info: bookInfo,
      pluginID: plugin.id,
      date: DateTime.now(),
      bookPage: bookPage,
    ));
    while (items.data.length > _MaxHistories) {
      items.data.removeLast();
    }
    items.update();
  }
}