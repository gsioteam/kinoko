
import 'dart:async';
import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:glib/main/data_item.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../configs.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';


String _generateMd5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}

class SizeResult {
  int cached = 0;
  int other = 0;
}

class PictureCacheManager extends BaseCacheManager {
  String key;
  bool _store = false;
  static Map<String, PictureCacheManager> _managers = Map();

  PictureCacheManager._(this.key, {
    Duration maxAgeCacheObject
  }) : super(
    key,
    maxAgeCacheObject: maxAgeCacheObject,
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

  static String cacheKey(DataItem item) {
    return "${item.projectKey}/${_generateMd5(item.link)}";
  }

  static Future<SizeResult> calculateCacheSize({Set<String> cached}) async {
    if (cached == null) cached = Set();
    var directory = await getTemporaryDirectory();
    String path = p.join(directory.path, "pic");
    var dir = Directory(path);
    SizeResult result = SizeResult();
    await for (var entry in dir.list(recursive: true, followLinks: false)) {
      if (entry is File) {
        var segs = entry.path.replaceFirst("$path/", "").split('/');
        if (segs.length > 2) {
          var key = "${segs[0]}/${segs[1]}";
          if (cached.contains(key)) {
            result.cached += (await entry.stat()).size;
          } else {
            result.other += (await entry.stat()).size;
          }
        }
      }
    }
    return result;
  }

  static Future<void> clearCache({Set<String> without}) async {
    if (without == null) without = Set();
    var directory = await getTemporaryDirectory();
    String path = p.join(directory.path, "pic");
    var dir = Directory(path);
    await for (var firstEntry in dir.list(followLinks: false)) {
      if (firstEntry is Directory) {
        String firstName = p.basename(firstEntry.path);
        await for (var secondEntry in firstEntry.list(followLinks: false)) {
          String secondName = p.basename(secondEntry.path);
          String key = "$firstName/$secondName";
          if (!without.contains(key)) {
            await secondEntry.delete(recursive: true);
          }
        }
        try {
          await firstEntry.delete();
        } catch (e) {
          // not empty
        }
      } else {
        await firstEntry.delete();
      }
    }
  }
}