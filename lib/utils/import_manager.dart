
import 'dart:convert';

import 'key_value_storage.dart';

class ImportedItem {
  String title;
  String path;

  ImportedItem({
    required this.title,
    required this.path
  });
  ImportedItem.fromData(dynamic data) :
        title = data["title"],
        path = data["path"];

  toData() {
    return {
      "title": title,
      "path": path,
    };
  }
}

class ImportManager {

  late KeyValueStorage<List<ImportedItem>> items;

  ImportManager._() {
    items = KeyValueStorage(
      key: 'import_items',
      decoder: (text) {
        if (text.isNotEmpty) {
          List list = jsonDecode(text);
          List<ImportedItem> ret = [];
          for (var data in list) {
            try {
              ret.add(ImportedItem.fromData(data));
            } catch (e) {
            }
          }
          return ret;
        } else {
          return [];
        }
      },
      encoder: (items) {
        return jsonEncode(items.map((e) => e.toData()).toList());
      }
    );
  }

  void add(ImportedItem item) {
    items.data.add(item);
    items.update();
  }

  void remove(ImportedItem item) {
    items.data.remove(item);
    items.update();
  }

  static ImportManager? _instance;
  static ImportManager get instance {
    if (_instance == null) {
      _instance = ImportManager._();
    }
    return _instance!;
  }
}