
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:path/path.dart' as p;

class AssetsFileSystem extends DappFileSystem {
  final String prefix;
  Map<String, Uint8List> map = {};
  late Future<void> _ready;
  Future<void> get ready => _ready;

  AssetsFileSystem({
    required BuildContext context,
    required this.prefix,
  }) {
    _ready = _setup(context);
  }

  Future<void> _setup(BuildContext context) async {
    final manifestJson = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    final list = json.decode(manifestJson).keys.where((String key) => key.startsWith(prefix));
    for (String path in list) {
      if (p.basename(path).startsWith('.')) continue;
      String str = path.replaceFirst(prefix, '');
      if (str[0] != '/') str = '/' + str;
      var data = await rootBundle.load(path);
      map[str] = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }
  }

  @override
  bool exist(String filename) {
    return map.containsKey(filename);
  }

  @override
  String? read(String filename) {
    var data = map[filename];
    if (data != null) {
      return utf8.decode(data);
    } else {
      return null;
    }
  }

  @override
  Uint8List? readBytes(String filename) {
    return map[filename];
  }
}