
import 'package:flutter/material.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:flutter_dapp/src/controller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kinoko/configs.dart';
import 'package:kinoko/pages/picture_viewer.dart';
import 'package:kinoko/pages/source_page.dart';
import 'package:kinoko/utils/history_manager.dart';

import 'book_info.dart';
import 'download_manager.dart';
import 'favorites_manager.dart';
import 'plugin/plugin.dart';
import 'plugin/utils.dart';
import '../localizations/localizations.dart';

class KiController extends Controller {
  Plugin plugin;
  KiController(JsScript script, this.plugin) : super(script);

  openBook(JsValue data) {
    var d = jsValueToDart(data);
    return Navigator.of(state!.context).push(MaterialPageRoute(builder: (context) {
      return PictureViewer(
        plugin: plugin,
        list: d["list"],
        initializeIndex: d["index"],
        page: d["page"],
      );
    }));
  }

  openBrowser(String url) {
    return Navigator.of(state!.context).push(MaterialPageRoute(builder: (context) {
      return SourcePage(
        url: url,
      );
    }));
  }

  addDownload(JsValue list) {
    int length = list["length"];
    for (int i = 0, t = length; i < t; ++i) {
      var data = list[i];
      DownloadManager().add(BookInfo.fromData(jsValueToDart(data)), plugin);
    }
    Fluttertoast.showToast(
        msg: lc(state!.context)("added_download").replaceFirst("{0}", length.toString())
    );
  }

  addFavorite(JsValue data, dynamic last) {
    var map = jsValueToDart(data);
    LastData? lastData;
    if (last is JsValue) {
      var map = jsValueToDart(last);
      lastData = LastData(
        name: map["title"],
        key: map["key"],
        updateTime: DateTime.now(),
      );
    }
    FavoritesManager().add(
        plugin,
        BookInfo.fromData(map),
        map["page"],
        lastData);
  }

  addHistory(JsValue data) {
    var map = jsValueToDart(data);
    HistoryManager().insert(
      BookInfo.fromData(map),
      map["page"],
      plugin
    );
  }
}

ClassInfo kiControllerInfo = controllerClass.inherit<KiController>(
    name: "_Controller",
    functions: {
      "openBook": JsFunction.ins((obj, argv) => obj.openBook(argv[0])),
      "openBrowser": JsFunction.ins((obj, argv) => obj.openBrowser(argv[0])),
      "addDownload": JsFunction.ins((obj, argv) => obj.addDownload(argv[0])),
      "addFavorite": JsFunction.ins((obj, argv) => obj.addFavorite(argv[0], argv[1])),
      "addHistory": JsFunction.ins((obj, argv) => obj.addHistory(argv[0])),
    }
);

ClassInfo downloadManager = ClassInfo(
    name: "DownloadManager",
    newInstance: (_, __) => throw Exception(),
    functions: {
      "exist": JsFunction.sta((argv) => DownloadManager().exist(argv[0])),
      "remove": JsFunction.sta((argv) => DownloadManager().removeKey(argv[0])),
    }
);

ClassInfo favoriteManager = ClassInfo(
    name: "FavoritesManager",
    newInstance: (_, __) => throw Exception(),
    functions: {
      "exist": JsFunction.sta((argv) => FavoritesManager().exist(argv[0])),
      "remove": JsFunction.sta((argv) => FavoritesManager().remove(argv[0])),
    }
);

abstract class NotificationCenter {
  static Map<String, List<JsValue>> observers = {};

  static void addObserver(String name, JsValue func) {
    var list = observers[name];
    if (list == null) {
      observers[name] = list = [];
    }
    list.add(func..retain());
  }

  static void removeObserver(String name, JsValue func) {
    var list = observers[name];
    if (list != null) {
      for (int i = 0, t = list.length; i < t; ++i) {
        var observer = list[i];
        if (observer == func) {
          observer.release();
          list.remove(observer);
          return;
        }
      }
    }
  }

  static void trigger(String name, dynamic data) {
    var list = observers[name];
    if (list != null) {
      for (var observer in list) {
        observer.call([data]);
      }
    }
  }
}

ClassInfo notificationCenter = ClassInfo<NotificationCenter>(
  newInstance: (_, __) => throw Exception("It is a abstract class"),
  functions: {
    "addObserver": JsFunction.sta((argv)=>NotificationCenter.addObserver(argv[0], argv[1])),
    "removeObserver": JsFunction.sta((argv)=>NotificationCenter.removeObserver(argv[0], argv[1])),
    "trigger": JsFunction.sta((argv)=>NotificationCenter.trigger(argv[0], argv[1])),
  }
);

class ScriptContext implements JsDispose {
  JsScript script;
  JsValue? _onEvent;

  ScriptContext() : script = JsScript() {
    Configs.instance.setupJS(script);
    script.global["postMessage"] = script.function((argv) => _onPostMessage(argv[0]));
  }

  eval(String str) {
    var ret = script.eval(str);
    if (ret is JsValue) {
      ret = jsValueToDart(ret);
    }
    return ret;
  }

  dispose() {
    script.dispose();
    _onEvent?.release();
  }

  _onPostMessage(dynamic data) {
    if (_onEvent != null)
      _onEvent!.call([dartToJsValue(_onEvent!.script, jsValueToDart(data))]);
  }

  JsValue? get onEvent {
    return _onEvent;
  }

  set onEvent(JsValue? val) {
    _onEvent?.release();
    _onEvent = val?..retain();
  }

  postMessage(data) {
    script.global.invoke("onmessage", [dartToJsValue(script, jsValueToDart(data))]);
  }
}

ClassInfo scriptContextClass = ClassInfo<ScriptContext>(
    newInstance: (_, __) => ScriptContext(),
    functions: {
      "eval": JsFunction.ins((obj, argv) => obj.eval(argv[0])),
      "postMessage": JsFunction.ins((obj, argv) => obj.postMessage(argv[0])),
    },
    fields: {
      "onmessage": JsField.ins(
        set: (obj, val) => obj.onEvent = val,
        get: (obj) => obj.onEvent,
      )
    }
);