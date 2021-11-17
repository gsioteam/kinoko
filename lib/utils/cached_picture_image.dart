
import 'dart:async';
import 'dart:io' as io;
import 'package:file/src/interface/file.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:glib/main/data_item.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../configs.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:file/file.dart' as file;
import 'package:file/local.dart';
import 'package:flutter_cache_manager/src/storage/file_system/file_system.dart';

String _generateMd5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}

class SizeResult {
  int cached = 0;
  int other = 0;
}

class PictureFileSystem extends FileSystem {
  String key;
  file.Directory? directory;

  PictureFileSystem(this.key);

  @override
  Future<File> createFile(String name) async {
    if (directory == null) {
      var temp = await getTemporaryDirectory();
      directory = LocalFileSystem().directory(p.join(temp.path, "pic", key));
      if (!await directory!.exists()) {
        await directory!.create(recursive: true);
      }
    }
    return directory!.childFile(name);
  }

}

class PictureCacheManager extends CacheManager {
  String key;
  bool _store = false;
  static Map<String, PictureCacheManager> _managers = {};

  PictureCacheManager._(this.key, {
    required Duration maxAgeCacheObject
  }) : super(Config(
    key,
    stalePeriod: maxAgeCacheObject,
    fileSystem: PictureFileSystem(key),
  ));

  factory PictureCacheManager(String key, DataItem item) {
    PictureCacheManager? manager = _managers[key];
    bool col = item.isInCollection(collection_download);
    if (manager?._store == col) {
      return manager!;
    } else {
      manager = PictureCacheManager._(key, maxAgeCacheObject: col ? Duration(days: 356 * 999) : Duration(days: 20));
      manager._store = col;
      _managers[key] = manager;
      return manager;
    }
  }

  static String cacheKey(DataItem item) {
    return "${item.projectKey}/${_generateMd5(item.link)}";
  }

  static Future<SizeResult> calculateCacheSize({Set<String>? cached}) async {
    if (cached == null) cached = Set();
    var directory = await getTemporaryDirectory();
    String path = p.join(directory.path, "pic");
    var dir = io.Directory(path);
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

  static Future<void> clearCache({Set<String>? without}) async {
    if (without == null) without = Set();
    var directory = await getTemporaryDirectory();
    String path = p.join(directory.path, "pic");
    var dir = io.Directory(path);
    await for (var firstEntry in dir.list(followLinks: false)) {
      if (firstEntry is io.Directory) {
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