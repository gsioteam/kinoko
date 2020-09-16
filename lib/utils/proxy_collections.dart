
import 'dart:collection';

class Proxy {
  dynamic target;
  dynamic index;

  Proxy(this.target, this.index);

  get() {
    if (index == null) {
      return target;
    } else if (target is ProxyCollection){
      return target._get(index);
    } else {
      return target[index];
    }
  }
}

abstract class ProxyCollection {
  dynamic _get(index);
}

class ProxyMap<K, V> extends ProxyCollection with MapMixin<K, V> {
  final Proxy _proxy;

  ProxyMap._(target, [index]) : _proxy = Proxy(target, index);
  factory ProxyMap(target) {
    if (target is Map) {
      return ProxyMap._(target);
    }
    return null;
  }

  @override
  V operator [](Object key) {
    var res = _proxy.get()[key];
    if (res is V) {
      if (res is Map) {
        return ProxyMap._(this, key) as V;
      } else if (res is List) {
        return ProxyList._(this, key) as V;
      } else return res;
    }
    return null;
  }

  @override
  void operator []=(K key, V value) {
    _proxy.get()[key] = value;
  }

  @override
  void clear() {
    _proxy.get().clear();
  }

  @override
  Iterable<K> get keys => _proxy.get().keys;

  @override
  V remove(Object key) {
    return _proxy.get().remove(key);
  }

  @override
  _get(index) {
    return _proxy.get()[index];
  }
}

class ProxyList<E> extends ProxyCollection with ListMixin<E> {
  final Proxy _proxy;

  ProxyList._(target, [index]) : _proxy = Proxy(target, index);
  factory ProxyList(target) {
    if (target is List) {
      return ProxyList(target);
    }
    return null;
  }

  @override
  int get length => _proxy.get().length;

  @override
  E operator [](int index) {
    var res = _proxy.get()[index];
    if (res is E) {
      if (res is Map) {
        return ProxyMap._(this, index) as E;
      } else if (res is List) {
        return ProxyList._(this, index) as E;
      } else return res;
    }
    return null;
  }

  @override
  void operator []=(int index, E value) {
    _proxy.get()[index] = value;
  }

  @override
  _get(index) {
    return _proxy.get()[index];
  }

  @override
  void set length(int newLength) {
  }
}

dynamic proxyObject(target) {
  if (target is Map) {
    return ProxyMap._(target);
  } else if (target is List) {
    return ProxyList._(target);
  } return target;
}