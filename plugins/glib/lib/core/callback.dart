

import 'dart:ffi';

import 'core.dart';

class Callback extends Base {
  static reg() {
    Base.reg(Callback, "gc::_Callback", Base).constructor = (ptr)=>Callback(ptr);
  }

  static Callback fromFunction(Function func) {
    if (func == null) return null;
    return FunctionCallback.allocate(func);
  }

  Callback(Pointer ptr) : super() {
    this.id = ptr;
  }

  invoke(List argv) {
    return call("invoke", argv:[argv]);
  }
}

class FunctionCallback extends Callback {

  Function function;

  Type get aliasType {
    return Callback;
  }

  FunctionCallback.allocate(this.function) : super(null) {
    super.allocate([]);
    this.on("_invoke", _invoke);
  }

  _invoke(List argv) {
    try {
      return Function.apply(function, argv);
    } catch (e) {
      print("Error when invoke $function $e");
    }
  }
}