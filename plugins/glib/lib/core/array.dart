import 'dart:collection';

import 'core.dart';

class Array extends Base with ListMixin<dynamic> {

  static reg() {
    Base.reg(Array, "gc::_Array", Base).constructor = (ptr)=>Array(ptr);
  }

  Array(ptr):super() {
    this.id = ptr;
  }

  Array.allocate(List list) {
    super.allocate([]);
    this.length = list.length;
    for (int i = 0, t = list.length; i < t; ++i) {
      this[i] = list[i];
    }
  }

  @override
  int get length {
    return call("size");
  }

  @override
  set length(int v) {
    return call("resize", argv: [v]);
  }

  @override
  dynamic operator [](int index) {
    return call("get", argv:[index]);
  }

  @override
  void operator []=(int index, dynamic value) {
    call("set", argv:[index, value]);
  }
  
  @override
  void add(element) {
    call("push_back", argv: [element]);
  }
  
  @override
  void insert(int index, element) {
    call("insert", argv: [index, element]);
  }

  @override
  removeAt(int index) {
    call("erase", argv: [index]);
  }

  Array copy() => call("copy");
}
