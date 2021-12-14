
import 'package:flutter/cupertino.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:kinoko/utils/favorites_manager.dart';
import 'package:kinoko/utils/plugin/plugin.dart';
import 'package:kinoko/utils/plugin/utils.dart';
import '../key_value_storage.dart';

class Picture {
  String? url;
  Map? headers;

  Picture({this.url, this.headers});

  Map<String, String>? get headersMap {
    Map<String, String>? map;
    if (headers != null) {
      map = Map<String, String>.from(headers!);
    };
    return map;
  }

  Map toData() => {
    "url": url,
    "headers": headers
  };
}

class Processor extends ValueNotifier<List<Picture>> {
  Plugin plugin;
  late JsValue jsProcessor;
  late JsValue data;
  ValueNotifier<bool> loading = ValueNotifier(false);
  bool _disposed = false;
  bool get isDisposed => _disposed;

  late KeyValueStorage<Map> storage;

  String? _key;
  String get key => _key ?? "";

  Processor({
    required this.plugin,
    required Object data,
  }) : super([]) {
    var script = plugin.script!;
    jsProcessor = plugin.makeProcessor(this)..retain();
    this.data = dartToJsValue(script, data);
    this.data.retain();

    _key = jsProcessor["key"];
    storage = KeyValueStorage(key: "processor:$_key");

    var list = storage.data["list"];
    if (list is List) {
      List<Picture> pics = [];
      for (var data in list) {
        pics.add(Picture(
          url: data["url"],
          headers: data["headers"],
        ));
      }
      this.value = pics;
    }
  }

  void _setDataAt(JsValue data, int index) {
    var map = jsValueToDart(data);
    while (value.length <= index) {
      value.add(Picture());
    }
    value[index] = Picture(
      url: map["url"],
      headers: map["headers"],
    );
    if (isDisposed) return;
    notifyListeners();
  }

  void _setData(JsValue data) {
    var list = jsValueToDart(data);
    List<Picture> newList = [];
    for (var map in list) {
      newList.add(Picture(
        url: map["url"],
        headers: map["headers"],
      ));
    }
    if (isDisposed) return;
    value = newList;
  }

  void _save(bool complete, JsValue? state) {
    storage.data = {
      "complete": complete,
      "state": state == null ? null : jsValueToDart(state),
      "list": value.map((e) => e.toData()).toList(),
    };
  }

  bool get isComplete {
    return storage.data["complete"] ?? false;
  }

  @override
  void dispose() {
    super.dispose();
    try {
      jsProcessor.invoke("unload");
    } catch (e) {
    }
    jsProcessor.release();
    data.release();
    _disposed = true;
    loading.dispose();
  }

  Future<void> load() async {
    if (isComplete && value.length > 0) return;
    if (isDisposed || loading.value) return;
    var ret = jsProcessor.invoke("load", [dartToJsValue(jsProcessor.script, storage.data["state"])]);
    if (ret is JsValue) {
      return ret.asFuture;
    }
  }

  Future<LastData> checkNew() async {
    if (isDisposed) throw Exception("Disposed");
    JsValue promise = jsProcessor.invoke("checkNew");
    var ret = await promise.asFuture;
    return LastData(
      name: ret["title"],
      key: ret["key"],
      updateTime: DateTime.now(),
    );
  }

  void reload() {
    storage.data = {};
    value = [];
    load();
  }

  String get title {
    if (data is Map) {
      return data["title"] ?? "-";
    }
    return "-";
  }
}

ClassInfo processorClass = ClassInfo<Processor>(
  newInstance: (_, __) => throw Exception("Processor is a abstract class"),
  functions: {
    "setDataAt": JsFunction.ins((obj, argv) => obj._setDataAt(argv[0], argv[1])),
    "setData": JsFunction.ins((obj, argv) => obj._setData(argv[0])),
    "save": JsFunction.ins((obj, argv) => obj._save(argv[0], argv[1])),
  },
  fields: {
    "data": JsField.ins(
      get: (obj) => obj.data,
    ),
    "loading": JsField.ins(
      get: (obj) => obj.loading.value,
      set: (obj, val) => obj.loading.value = val,
    ),
    "disposed": JsField.ins(
      get: (obj) => obj.isDisposed,
    )
  }
);