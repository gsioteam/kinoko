
import 'dart:typed_data';

import 'package:js_script/js_script.dart';

abstract class DappFileSystem extends JsFileSystem {
  Uint8List? readBytes(String filename);
}

extension DappFileSystemList on List<DappFileSystem> {
  Uint8List? loadFile(String path) {
    if (isEmpty) return null;
    for (var fileSystem in this) {
      var buf = fileSystem.readBytes(path);
      if (buf != null) return buf;
    }
    return null;
  }
}