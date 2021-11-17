
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dapp/extensions/extension.dart';
import 'package:flutter_dapp/src/flutter_dapp.dart';
import 'package:js_script/js_script.dart';

/// Contains `HTTPParser`
class HTMLParser extends Extension {
  @override
  Future<String> loadCode(BuildContext context) {
    return rootBundle.loadString("packages/flutter_dapp/js_env/html.min.js");
  }

  @override
  void setup(JsScript script) { }

}