
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PictureCacheManager extends BaseCacheManager {
  String key;

  PictureCacheManager(this.key, {
    Duration maxAgeCacheObject,
  }) : super(
      key,
      maxAgeCacheObject: maxAgeCacheObject
  );

  @override
  Future<String> getFilePath() async {
    var directory = await getTemporaryDirectory();
    String result = p.join(directory.path, "pic", key);
    print("Result $result");
    return result;
  }

}