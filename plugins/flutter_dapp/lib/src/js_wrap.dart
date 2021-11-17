
import 'dart:collection';

import 'package:js_script/js_script.dart';

wrap(object) {
  if (object is JsValue) {
    if (object.isArray) {
      return DataList(object);
    } else {
      return DataMap(object);
    }
  } else {
    return object;
  }
}

unwrap(object) {
  if (object is DataMap) {
    return object.value;
  } else if (object is DataList) {
    return object.value;
  } else {
    return object;
  }
}

class DataList with List, ListMixin, JsProxy {
  JsValue value;
  DataList(this.value);

  @override
  int get length => value["length"];
  set length(int len) => value["length"] = len;

  @override
  operator [](int index) {
    return wrap(value[index]);
  }

  @override
  void operator []=(int index, value) {
    this.value[index] = unwrap(value);
  }

}

class DataMap with Map, MapMixin, JsProxy {
  JsValue value;

  DataMap(this.value);

  @override
  operator [](Object? key) {
    return wrap(value[key]);
  }

  @override
  void operator []=(key, value) {
    this.value[key] = unwrap(value);
  }

  @override
  void clear() {
  }

  @override
  Iterable get keys sync* {
    for (var key in value.getOwnPropertyNames()) {
      yield key;
    }
  }

  @override
  remove(Object? key) {
  }

}