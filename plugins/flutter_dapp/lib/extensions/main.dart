
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dapp/extensions/extension.dart';
import 'package:flutter_dapp/src/flutter_dapp.dart';
import 'package:js_script/js_script.dart';


///
/// Contains `Buffer`, `URL`, `setTimeout`, `atob`, `btoa`, `Event`,
/// `EventTarget`  functions.
class Main extends Extension {
  @override
  Future<String> loadCode(BuildContext context) {
    return rootBundle.loadString("packages/flutter_dapp/js_env/index.min.js");
  }

  @override
  void setup(JsScript script) { }

}