
import 'dart:async';
import 'dart:convert';

import 'package:glib/core/array.dart';
import 'package:glib/core/callback.dart';
import 'package:glib/main/collection_data.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/project.dart';
import '../configs.dart';

class FavCheckItem {
  CollectionData data;
  DataItem item;
  DateTime _date;
  String _checkValue;
  void Function() onStateChanged;

  factory FavCheckItem.from(CollectionData data) {
    if (data == null) return null;
    DataItem item = DataItem.fromCollectionData(data);
    if (item == null) {
      return null;
    }
    return FavCheckItem(data.control(), item.control());
  }

  FavCheckItem(this.data, this.item) {
    _loadData();
  }

  dispose() {
    this.data.release();
  }

  bool get hasNew {
    return this.data.flag == 1;
  }

  void clearNew() {
    this.data.flag = 0;
    this.data.save();
  }

  Future<void> _updateValue(bool first, Project project, Context context) async {
    Completer completer = Completer();
    context.on_reload_complete = Callback.fromFunction(() {
      Array resultData = context.data;

      if (resultData.length > 0) {
        DataItem item = resultData[0];
        data.setJSONData({
          "date": _date.toString(),
          "value": item.link
        });
        _date = DateTime.now();
        if (_checkValue != item.link && !first) {
          data.flag = 1;
          onStateChanged?.call();
        }
        data.save();
      }

      completer.complete();
    }).release();
    context.reload();
    return completer.future;
  }

  void checkNew(bool first) async {
    Project project = Project.allocate(item.projectKey);
    if (!project.isValidated) {
      project.release();
      return;
    }
    DataItemType type = item.type;
    if (type == DataItemType.Book) {
      Context context = project.createBookContext(item).control();
      await _updateValue(first, project, context);
      context.release();
    }
    project.release();
  }

  void _loadData() {
    if (data.data != null && data.data.isNotEmpty) {
      Map<String, dynamic> map = jsonDecode(data.data);
      String date = map["date"];
      if (date != null) {
        _date = DateTime.parse(date);
      }
      _checkValue = map["value"];
    }
  }

  DateTime get date => _date;
}

class FavoritesManager {
  static FavoritesManager _instance;
  List<FavCheckItem> items = List();
  Timer _timer;

  factory FavoritesManager() {
    if (_instance == null) {
      _instance = FavoritesManager._();
    }
    return _instance;
  }

  FavoritesManager._() {
    Array data = CollectionData.all(collection_mark);
    for (int  i = 0, t = data.length; i < t; ++i) {
      CollectionData d = data[i];
      FavCheckItem item = FavCheckItem.from(d);
      if (item != null)
        items.add(item);
    }
    _timer = Timer.periodic(Duration(minutes: 30), (timer) {
      checkNew();
    });
  }

  void add(DataItem item) {
    if (!item.isInCollection(collection_mark)) {
      CollectionData data = item.saveToCollection(collection_mark, {
        "date": DateTime.now().toString()
      });
      if (data != null) {
        FavCheckItem checkItem = FavCheckItem(data.control(), item.control());
        items.add(checkItem);
        checkItem.checkNew(true);
      } else {
      }
    } else {
      print("${item.title} already added!");
    }
  }

  void remove(dynamic item) {
    if (item is DataItem) {
      if (item.isInCollection(collection_mark)) {
        item.removeFromCollection(collection_mark);
        List needRemove = [];
        for (int i = 0, t = items.length; i < t; ++i) {
          FavCheckItem checkItem = items[i];
          if (checkItem.item.link == item.link) {
            needRemove.add(checkItem);
          }
        }
        needRemove.forEach((element) {
          items.remove(element);
        });
      }
    } else if (item is FavCheckItem) {
      if (items.contains(item)) {
        item.item.removeFromCollection(collection_mark);
        items.remove(item);
      }
    }
  }

  void checkNew() async {
    for (int i = 0, t = items.length; i < t; ++i) {
      FavCheckItem checkItem = items[i];
      await checkItem.checkNew(false);
    }
  }

  bool isFavorite(DataItem item) {
    return item.isInCollection(collection_mark);
  }

  void clearNew(DataItem item) {
    if (isFavorite(item)) {
      for (int i = 0, t = items.length; i < t; ++i) {
        FavCheckItem checkItem = items[i];
        if (checkItem.item.link == item.link) {
          checkItem.clearNew();
        }
      }
    }
  }
}