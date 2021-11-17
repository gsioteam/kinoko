
import 'package:flutter/widgets.dart';
import 'package:js_script/js_script.dart';

class StateValue {

  State state;

  StateValue(this.state);

  void setup(JsValue jsValue) {
    var state = this.state;
    if (state is DAppState) {
      state._methods.forEach((key, value) {
        jsValue[key] = value;
      });
    }
  }
}

ClassInfo stateClass = ClassInfo<StateValue>(
  newInstance: (script, _)=>throw Exception("This is abstract class"),
);

abstract class DAppState<T extends StatefulWidget> extends State<T> {

  Map<String, Function> _methods = {};

  void registerMethod(String name, Function function) {
    _methods[name] = function;
  }
}