
import 'dart:async';
import 'package:ffi/ffi.dart';
import 'array.dart';
import 'callback.dart';
import 'gmap.dart';
import 'dart:ffi';
import 'binds.dart';

Map<Pointer, TypeInfo> _classDB = Map();
Map<Type, TypeInfo> _classRef = Map();
Map<Pointer, Base> _objectDB = Map<Pointer, Base>();

class TypeInfo {
  Type type, superType;
  Pointer ptr;
  Map<String, Function> functions = Map();
  dynamic Function(Pointer) constructor;

  TypeInfo(this.type, this.ptr, this.superType);
}

mixin AutoRelease {
  static Set<AutoRelease> _cachePool = Set();
  static Timer timer;
  int _retainCount = 1;
  bool _destroyed = false;

  control() {
    _retainCount ++;
    if (_retainCount > 0) {
      _cachePool.remove(this);
    }
    return this;
  }

  release() {
    if (_retainCount <= 0) {
      throw Exception("Object already release!");
    }
    _retainCount--;
    if (_retainCount <= 0 && !_cachePool.contains(this)) {
      _cachePool.add(this);
    }

    if (timer == null) {
      timer = Timer.periodic(Duration(milliseconds: 20), _timeUp);
    }
    return this;
  }

  static _timeUp(Timer t) {
    t.cancel();
    Set<AutoRelease> copyList = Set<AutoRelease>.from(_cachePool);
    _cachePool.clear();
    copyList.forEach((AutoRelease tar){
      tar.destroy();
      tar._destroyed = true;
    });
    timer = null;
  }

  destroy() {
  }

  bool get isDestroyed => _destroyed;
}

class AutoPointer<T extends NativeType> with AutoRelease {
  Pointer<T> ptr;
  AutoPointer(this.ptr);

  @override
  destroy() {
    malloc.free(ptr);
  }
}

void _toNative(dynamic obj, Pointer<NativeTarget> ret) {
  NativeTarget nt = ret[0];
  if (obj is int) {
    nt.type = TypeInt;
    nt.intValue = obj;
  } else if (obj is double) {
    nt.type = TypeDouble;
    nt.doubleValue = obj;
  } else if (obj is bool) {
    nt.type = TypeBoolean;
    nt.intValue = obj ? 1 : 0;
  } else if (obj is Base) {
    nt.type = TypeObject;
    nt.pointerValue = obj._id;
  } else if (obj is String) {
    nt.type = TypeString;
    Pointer<Utf8> utf8 = obj.toNativeUtf8();
    nt.pointerValue = utf8;
    autorelease(utf8);
  } else if (obj is List) {
    Array arr = Array.allocate(obj);
    _toNative(arr, ret);
    arr.release();
  } else if (obj is Map) {
    GMap map = GMap.allocate(obj);
    _toNative(map, ret);
    map.release();
  } else if (obj is Function) {
    Callback cb = Callback.fromFunction(obj);
    _toNative(cb, ret);
    cb.release();
  } else if (obj is Pointer) {
    nt.type = TypePointer;
    nt.pointerValue = obj;
  } else {
    nt.type = 0;
  }
}

Pointer<NativeTarget> _makeArgv(List<dynamic> argv) {
  Pointer<NativeTarget> argvPtr = malloc.allocate<NativeTarget>(argv.length * sizeOf<NativeTarget>());
  for (int i = 0, t = argv.length; i < t; ++i) {
    _toNative(argv[i], argvPtr.elementAt(i));
  }
  return argvPtr;
}

List<dynamic> _convertArgv(Pointer<NativeTarget> argv, int length) {
  List<dynamic> results = List(length);
  for (int i = 0; i < length; ++i) {
    NativeTarget target = argv[i];
    dynamic ret;
    switch (target.type) {
      case TypeInt: {
        ret = target.intValue;
        break;
      }
      case TypeDouble: {
        ret = target.doubleValue;
        break;
      }
      case TypeObject: {
        ret = _objectDB[target.pointerValue];
        break;
      }
      case TypeString: {
        ret = Pointer<Utf8>.fromAddress(target.pointerValue.address).toDartString();
        break;
      }
      case TypeBoolean: {
        ret = (target.intValue != 0);
        break;
      }
      case TypePointer: {
        ret = target.pointerValue;
        break;
      }
      default: {
        ret = null;
      }
    }
    results[i] = ret;
  }
  return results;
}

void autorelease<T extends NativeType>(Pointer<T> ptr) {
  AutoPointer<T>(ptr).release();
}

void _callClassFromNative(Pointer ptr, Pointer<Utf8> name, Pointer<NativeTarget> argv, int length, Pointer<NativeTarget> result) {
  String fun = name.toDartString();
  try {
    TypeInfo type = _classDB[ptr];
    if (type != null) {
      Function func = type.functions[fun];
      if (func != null) {
        dynamic ret = Function.apply(func, _convertArgv(argv, length));
        _toNative(ret, result);
      }
    }
  } catch (e, stacktrace) {
    print("Call static $fun failed : ${e.toString()} \n$stacktrace");
  }
}

void _callInstanceFromNative(Pointer ptr, Pointer<Utf8> name, Pointer<NativeTarget> argv, int length, Pointer<NativeTarget> result) {
  String fun = name.toDartString();
  Base ins = _objectDB[ptr];
  try {
    dynamic ret = ins.apply(fun, _convertArgv(argv, length));
    _toNative(ret, result);
  }catch (e, stacktrace) {
    print("Call $fun on $ins failed : ${e.toString()} \n$stacktrace");
  }
}

int _createNativeTarget(Pointer type, Pointer ptr) {
  var typeinfo = _classDB[type];
  if (typeinfo != null) {
    var cons = typeinfo.constructor;
    while (cons == null) {
      var sup = typeinfo.superType;
      if (sup != null) {
        typeinfo = _classRef[sup];
        cons = typeinfo.constructor;
      } else break;
    }
    if (cons != null) {
      _objectDB[ptr] = cons(ptr).release();
      return 0;
    }
  }
  return -1;
}

const ret = -1;
Pointer<NativeFunction<CallHandler>> callClassPointer = Pointer.fromFunction(_callClassFromNative);
Pointer<NativeFunction<CallHandler>> callInstancePointer = Pointer.fromFunction(_callInstanceFromNative);
Pointer<NativeFunction<CreateNative>> createNativeTarget = Pointer.fromFunction(_createNativeTarget, ret);

class Base with AutoRelease {

  Map<String, Function> functions = Map();
  Pointer _id;
  TypeInfo _type;

  dynamic call(String name, { argv: const <dynamic>[]}) {
    if (isDestroyed) {
      throw new Exception("This object($runtimeType) is destroyed.");
    }
    Pointer<NativeTarget> argvPtr = _makeArgv(argv);
    Pointer<Utf8> namePtr = name.toNativeUtf8();
    Pointer<NativeTarget> resultPtr = callObject(_id, namePtr, argvPtr, argv.length);
    List<dynamic> ret = _convertArgv(resultPtr, 1);

    malloc.free(namePtr);
    malloc.free(argvPtr);
    freePointer(resultPtr);

    var obj = ret[0];
    return obj;
  }

  static dynamic s_call(Type type, String name, {argv: const <dynamic>[]}) {
    TypeInfo typeInfo = _classRef[type];
    if (typeInfo != null) {
      Pointer<NativeTarget> argvPtr = _makeArgv(argv);
      Pointer<Utf8> namePtr = name.toNativeUtf8();
      Pointer<NativeTarget> resultPtr = callClass(typeInfo.ptr, namePtr, argvPtr, argv.length);

      List<dynamic> ret = _convertArgv(resultPtr, 1);

      malloc.free(namePtr);
      malloc.free(argvPtr);
      freePointer(resultPtr);

      return ret[0];
    }
  }

  void on(String name, Function func) {
    functions[name] = func;
  }

  dynamic apply(String name, List<dynamic> argv) {
    if (functions.containsKey(name)) {
      return Function.apply(functions[name], argv);
    }
    return null;
  }

  Type get aliasType {
    return this.runtimeType;
  }

  void initialize() {
    Type t = this.aliasType;
    while (t != null) {
      if (_classRef.containsKey(t)) {
        _type = _classRef[t];
        break;
      }
      t = Base;
    }
  }

  Base() {
    initialize();
  }

  set id(Pointer v) {
    if (this._id == null) {
      this._id = v;
    }
  }

  dynamic setID(Pointer v) {
    this.id = v;
    return this;
  }

  static bool setuped = false;

  void allocate(List<dynamic> argv) {
    if (!setuped) {
      throw new Exception("Can not create ${this.runtimeType} because glib is destroyed.");
    }
    Pointer<NativeTarget> argvPtr = _makeArgv(argv);
    _id = createObject(_type.ptr, argvPtr, argv.length);
    malloc.free(argvPtr);
    _objectDB[_id] = this;
  }

  static TypeInfo reg(Type type, String name, Type superType) {
    if (!setuped) {
      setuped = true;
      setupLibrary(callClassPointer, callInstancePointer, createNativeTarget);
    }
    Pointer<Utf8> pname = name.toNativeUtf8();
    Pointer handler = bindClass(pname);
    if (handler.address != 0) {
      TypeInfo info = TypeInfo(type, handler, superType);
      _classDB[handler] = info;
      _classRef[type] = info;
      malloc.free(pname);
      return info;
    } else {
      throw new Exception("Unkown class $type with $name");
    }
  }

  void destroy() {
    if (_id != null) {
      freeObject(_id);
      _objectDB.remove(_id);
      _id = null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is Base) {
      return _id == other._id;
    }
    return super == other;
  }

  @override
  int get hashCode => _id.hashCode + 0xfabc;

}

void r(Base b) {if (b != null) b.release();}

void destroyAllObject() {
  _objectDB.forEach((key, value) {
    value._destroyed = true;
  });
  _objectDB.clear();
  _classDB.clear();
  _classRef.clear();
}