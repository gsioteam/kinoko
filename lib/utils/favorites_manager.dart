
import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:glib/core/array.dart';
import 'package:glib/core/callback.dart';
import 'package:glib/main/collection_data.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/project.dart';
import '../configs.dart';

class FavAttachment {
  DateTime date;
  String link;
  int index;
  String last;

  FavAttachment.fromData(dynamic data) {
    fill(data);
  }

  void fill(dynamic data) {
    date = DateTime.tryParse(data['date']);
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

class FavCheckItem extends ValueNotifier<bool> {
  CollectionData data;
  DataItem item;

  FavAttachment attachment;

  ValueNotifier<bool> newListenable = ValueNotifier(false);

  factory FavCheckItem.from(CollectionData data) {
    if (data == null) return null;
    DataItem item = DataItem.fromCollectionData(data);
    if (item == null) {
      return null;
    }
    return FavCheckItem(data.control(), item.control());
  }

  FavCheckItem(this.data, this.item) : super(false) {
    attachment = FavAttachment.fromData(jsonDecode(data.data));
    _loadData();
  }

  dispose() {
    super.dispose();
    this.data.release();
    newListenable.dispose();
  }

  bool get hasNew => newListenable.value;

  void clearNew() {
    this.data.flag = 0;
    this.data.save();
    newListenable.value = false;
  }

  Future<void> _updateValue(bool first, Project project, Context context) async {
    Completer completer = Completer();
    context.onReloadComplete = Callback.fromFunction(() {
      Array resultData = context.data;

      if (resultData.length > 0) {
        DataItem item = resultData[0];
        // dynamic dataItem = context.infoData;
        // if (dataItem is DataItem) {
        //   item.title = dataItem.title;
        //   item.subtitle = dataItem.subtitle;
        // }
        attachment.date = DateTime.now();
        if (attachment.link != item.link && !first) {
          data.flag = 1;
          newListenable.value = true;
        }
        if (attachment.last != item.title) {
          attachment.last = item.title;
        }
        synchronize();
      }

      completer.complete();
    }).release();
    context.reload();
    return completer.future;
  }

  Future<void> checkNew(bool first) async {
    if (!first) {
      if (attachment.date.compareTo(DateTime.now().subtract(Duration(minutes: 30))) > 0) {
        return;
      }
    }
    Project project = Project.allocate(item.projectKey);
    if (!project.isValidated) {
      project.release();
      return;
    }
    DataItemType type = item.type;
    if (type == DataItemType.Data) {
      value = true;
      Context context = project.createCollectionContext(BOOK_INDEX, item).control();
      context.autoReload = true;
      await _updateValue(first, project, context);
      context.release();
      value = false;
    }
    project.release();
  }

  void _loadData() {
    if (data.data != null && data.data.isNotEmpty) {
      Map<String, dynamic> map = jsonDecode(data.data);
      attachment.fill(map);
    }
    newListenable = ValueNotifier(this.data.flag == 1);
  }

  bool get loading => value;

  void synchronize() {
    data.setJSONData(attachment.toData());
    data.save();
  }
}

class FavoritesManager {
  static FavoritesManager _instance;
  List<FavCheckItem> items = [];
  Timer _timer;
  ChangeNotifier onState = ChangeNotifier();

  factory FavoritesManager() {
    if (_instance == null) {
      _instance = FavoritesManager._();
    }
    return _instance;
  }

  FavoritesManager._() {
    Array data = CollectionData.all(collection_mark);
    bool hasIndex = true;
    for (int  i = 0, t = data.length; i < t; ++i) {
      CollectionData d = data[i];
      FavCheckItem item = FavCheckItem.from(d);
      if (item != null)
        _addItem(item);
      if (item.attachment.index == null) {
        hasIndex = false;
      }
    }
    if (hasIndex) {
      items.sort((item1, item2) {
        return item1.attachment.index - item2.attachment.index;
      });
    } else {
      for (int i = 0, t = items.length; i < t; ++i) {
        var item = items[i];
        item.attachment.index = i;
        item.synchronize();
      }
    }
    _timer = Timer.periodic(Duration(minutes: 2), (timer) {
      checkNew();
    });
    checkNew();
  }

  bool get hasNew {
    for (var item in items) {
      if (item.hasNew) return true;
    }
    return false;
  }

  void add(DataItem item) {
    if (!item.isInCollection(collection_mark)) {
      CollectionData data = item.saveToCollection(collection_mark, {
        "date": DateTime.now().toString()
      });
      if (data != null) {
        FavCheckItem checkItem = FavCheckItem(data.control(), item.control());
        _addItem(checkItem);
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
          _removeItem(element);
        });
      }
    } else if (item is FavCheckItem) {
      if (items.contains(item)) {
        item.item.removeFromCollection(collection_mark);
        _removeItem(item);
      }
    }
  }

  void _itemStateUpdate() {
    onState.notifyListeners();
  }

  void _addItem(FavCheckItem item) {
    item.newListenable.addListener(_itemStateUpdate);
    items.add(item);
  }

  void _removeItem(FavCheckItem item) {
    item.newListenable.removeListener(_itemStateUpdate);
    items.remove(item);
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

  void reorder() {
    for (int i = 0, t = items.length; i < t; ++i) {
      var item = items[i];
      item.attachment.index = i;
      item.synchronize();
    }
  }
}