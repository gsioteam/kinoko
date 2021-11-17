
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dapp/flutter_dapp.dart';

class IOFileSystem extends DappFileSystem {

  Map<String, Uint8List> _memoryCache = {};
  final Directory dir;
  IOFileSystem(this.dir);

  @override
  bool exist(String filename) {
    bool ret = _memoryCache.containsKey(filename);
    if (!ret) {
      ret = File("${dir.path}/$filename").existsSync();
    }
    return ret;
  }

  @override
  String? read(String filename) {
    if (_memoryCache.containsKey(filename)) {
      return utf8.decode(_memoryCache[filename]!);
    } else {
      var data = File("${dir.path}/$filename").readAsBytesSync();
      _memoryCache[filename] = data;
      return utf8.decode(data);
    }
  }

  @override
  Uint8List? readBytes(String filename) {
    if (_memoryCache.containsKey(filename)) {
      return _memoryCache[filename];
    } else {
      var data = File("${dir.path}/$filename").readAsBytesSync();
      _memoryCache[filename] = data;
      return data;
    }
  }

}