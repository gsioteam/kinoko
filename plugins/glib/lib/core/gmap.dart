
import 'dart:collection';

import 'array.dart';

import 'core.dart';

class GMap<V> extends Base with MapMixin<String, V> {
  static reg() {
    Base.reg(GMap, "gc::_Map", Base).constructor = (ptr)=>GMap(ptr);
  }

  GMap(int ptr) {
    this.id = ptr;
  }

  GMap.allocate(Map map) {
    super.allocate([]);
    map.forEach((k, v)=>{this[k] = v});
  }

  @override
  V operator [](Object key) {
    return call("get", argv:[key.toString()]);
  }

  @override
  void operator []=(String key, V value) {
    call("set", argv:[key, value]);
  }

  @override
  void clear() {
    call("clear");
  }

  @override
  Iterable<String> get keys {
    Array keys = call("keys");
    Iterable.generate(keys.length, (i) {
      return keys[i];
    });
  }

  @override
  V remove(Object key) {
    V ret = this[key];
    call("erase", argv:[key.toString()]);
    return ret;
  }
}