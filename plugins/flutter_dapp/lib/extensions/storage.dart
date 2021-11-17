
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dapp/extensions/extension.dart';
import 'package:flutter_dapp/src/flutter_dapp.dart';
import 'package:js_script/js_script.dart';

abstract class LocalStorage {

  void set(String key, String value);

  String? get(String key);

  void remove(String key);

  void clear();
}

ClassInfo storageClass = ClassInfo<LocalStorage>(
    newInstance: (_, __) => throw Exception("This is a abstract class"),
    functions: {
      "set": JsFunction.ins((obj, argv) => obj.set(argv[0], argv[1])),
      "get": JsFunction.ins((obj, argv) => obj.get(argv[0])),
      "remove": JsFunction.ins((obj, argv) => obj.remove(argv[0])),
      "clear": JsFunction.ins((obj, argv) => obj.clear()),
    }
);

///
/// The implementation of `localStorage`
class Storage extends Extension {

  LocalStorage localStorage;
  Storage({
    required this.localStorage,
  });

  @override
  Future<String> loadCode(BuildContext context) {
    return rootBundle.loadString("packages/flutter_dapp/js_env/storage.min.js");
  }

  @override
  void setup(JsScript script) {
    JsValue value = script.bind(localStorage, classInfo: storageClass);
    script.global['_storage'] = value;
  }

}