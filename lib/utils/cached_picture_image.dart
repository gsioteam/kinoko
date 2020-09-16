
import 'dart:async';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:glib/main/data_item.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../configs.dart';

class PictureCacheManager extends BaseCacheManager {
  String key;
  bool _store = false;
  static Map<String, PictureCacheManager> _managers = Map();

  PictureCacheManager._(this.key, {
    Duration maxAgeCacheObject
  }) : super(
    key,
    maxAgeCacheObject: maxAgeCacheObject
  );

  factory PictureCacheManager(String key, DataItem item) {
    PictureCacheManager manager = _managers[key];
    bool col = item.isInCollection(collection_download);
    if (manager?._store == col) {
      return manager;
    } else {
      manager = PictureCacheManager._(key, maxAgeCacheObject: col ? Duration(days: 356 * 999) : Duration(days: 20));
      manager._store = col;
      _managers[key] = manager;
      return manager;
    }
  }

  @override
  Future<String> getFilePath() async {
    var directory = await getTemporaryDirectory();
    String result = p.join(directory.path, "pic", key);
    return result;
  }

}