
import 'dart:async';

import 'package:js_script/js_script.dart';

class _Timer {

  late Timer _timer;
  final int milliseconds;
  final bool repeat;
  JsValue? _onTimeout;

  _Timer(this.milliseconds, this.repeat);

  JsValue? get onTimeout => _onTimeout;
  set onTimeout(JsValue? func) {
    _onTimeout?.release();
    _onTimeout = func?..retain();
  }

  void _timeout() {
    onTimeout?.call();
    if (repeat) {
      _timer = Timer(Duration(milliseconds: milliseconds), _timeout);
    } else {
      onTimeout = null;
    }
  }

  void start() {
    _timer = Timer(Duration(milliseconds: milliseconds), _timeout);
  }

  void stop() {
    _timer.cancel();
    onTimeout = null;
  }
}

ClassInfo timerClass = ClassInfo<_Timer>(
    name: "Timer",
    newInstance: (_, argv) {
      return _Timer(argv[0], argv[1]);
    },
    fields: {
      "onTimeout": JsField.ins(
        get: (obj) => obj.onTimeout,
        set: (obj, v) => obj.onTimeout = v,
      )
    },
    functions: {
      "start": JsFunction.ins((obj, argv) => obj.start()),
      "stop": JsFunction.ins((obj, argv) => obj.stop())
    }
);