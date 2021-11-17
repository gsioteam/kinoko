
import 'dart:typed_data';

import 'package:js_script/js_script.dart';

abstract class DappFileSystem extends JsFileSystem {
  Uint8List? readBytes(String filename);
}