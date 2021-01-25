
import 'dart:convert';

import 'package:glib/core/array.dart';
import 'package:glib/core/gmap.dart';
import 'package:glib/main/collection_data.dart';
import 'package:glib/main/data_item.dart';
import '../configs.dart';

class HistoryItem {
  CollectionData _collectionData;
  DataItem _item;
  DataItem get item => _item;
  DateTime _date;
  DateTime get date => _date;

  CollectionData get data => _collectionData;

  HistoryItem(CollectionData collectionData, [DataItem item]) {
    _collectionData = collectionData.control();
    if (item == null) {
      _item = DataItem.fromCollectionData(_collectionData)?.control();
    } else {
      _item = item.control();
    }
    try {
      var json = jsonDecode(_collectionData.data);
      var time = json["time"];
      if (time is int)
        _date = DateTime.fromMicrosecondsSinceEpoch(time);
      else _date = DateTime.fromMicrosecondsSinceEpoch(0);
    } catch (e) {
      _date = DateTime.fromMicrosecondsSinceEpoch(0);
    }
  }

  void dispose() {
    _collectionData?.release();
    _item?.release();
  }

  void update() {
    _date = DateTime.now();
    GMap map = GMap.allocate({
      "time": _date.microsecondsSinceEpoch
    });
    _collectionData.setJSONData(map);
    map.release();
    _collectionData.save();
  }
}

class HistoryManager {
  void Function() onChange;
  static HistoryManager _instance;
  List<HistoryItem> _items;

  factory HistoryManager() {
    if (_instance == null) {
      _instance = HistoryManager._();
    }
    return _instance;
  }

  HistoryManager._();

  List<HistoryItem> get items {
    if (_items == null) {
      var items = CollectionData.all(history_key);
      _items = List();

      for (CollectionData data in items) {
        _items.add(HistoryItem(data));
      }
      _items.sort((item1, item2) {
        return item2.date.difference(item1.date).inSeconds;
      });
    }
    return _items;
  }

  static const int ITEM_COUNT = 60;

  void clear() {
    for (var item in items) {
      item.data.remove();
      item.dispose();
    }
    items.clear();
    onChange?.call();
  }

  void insert(DataItem dataItem) {
    var link = dataItem.link;
    HistoryItem foundItem;
    for (var item in items) {
      if (item.item.link == link) {
        foundItem = item;
      }
    }
    if (foundItem == null) {
      CollectionData cData = dataItem.saveToCollection(history_key);
      foundItem = HistoryItem(cData, dataItem);
      items.insert(0, foundItem);
      while (items.length > ITEM_COUNT) {
        var item = items.removeLast();
        item.data.remove();
        item.dispose();
      }
    } else {
      items.remove(foundItem);
      items.insert(0, foundItem);
    }

    foundItem.update();
    onChange?.call();
  }
}