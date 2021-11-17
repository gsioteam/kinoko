
import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../src/flutter_dapp.dart';

abstract class Extension {

  JsCompiled? compiled;

  Future<void> initialize(BuildContext context, JsScript compiler) async {
    compiled = compiler.compile(await loadCode(context));
  }

  Future<String> loadCode(BuildContext context);
  void setup(JsScript script);

  void attachTo(JsScript script) {
    assert(compiled != null);
    setup(script);
    script.loadCompiled(compiled!);
  }
}