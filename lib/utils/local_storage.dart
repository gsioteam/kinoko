
import 'package:flutter_dapp/extensions/storage.dart';
import 'package:glib/main/models.dart';
import 'package:kinoko/utils/key_value_storage.dart';

class DataLocalStorage extends KeyValueStorage<Map> implements LocalStorage {

  DataLocalStorage(String id) : super(
    key: "local_storage:$id"
  );

  @override
  void clear() {
    data.clear();
    update();
  }

  @override
  String? get(String key) {
    return data[key];
  }

  @override
  void remove(String key) {
    data.remove(key);
    update();
  }

  @override
  void set(String key, String value) {
    data[key] = value;
    update();
  }

}