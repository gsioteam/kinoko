
import 'dart:collection';
import 'dart:ffi';

import 'array.dart';

import 'core.dart';

class GMap extends Base with MapMixin<String, dynamic> {
  static reg() {
    Base.reg(GMap, "gc::_Map", Base).constructor = (ptr)=>GMap(ptr);
  }

  GMap(Pointer ptr) {
    this.id = ptr;
  }

  GMap.allocate(Map<dynamic, dynamic> map) {
    super.allocate([]);
    map.forEach((k, v)=>this[k] = v);
  }

  @override
  dynamic operator [](Object key) {
    return call("get", argv:[key.toString()]);
  }

  @override
  void operator []=(String key, dynamic value) {
    call("set", argv:[key, value]);
  }

  @override
  void clear() {
    call("clear");
  }

  @override
  Iterable<String> get keys {
    Array keys = call("keys");
    return Iterable.generate(keys.length, (i) {
      return keys[i];
    });
  }

  @override
  dynamic remove(Object key) {
    dynamic ret = this[key];
    call("erase", argv:[key.toString()]);
    return ret;
  }
}