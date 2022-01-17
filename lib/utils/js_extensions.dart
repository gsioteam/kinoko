
import 'package:browser_webview/browser_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:flutter_dapp/src/controller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kinoko/configs.dart';
import 'package:kinoko/pages/picture_viewer.dart';
import 'package:kinoko/pages/source_page.dart';
import 'package:kinoko/utils/history_manager.dart';
import 'package:kinoko/utils/picture_data.dart';

import 'book_info.dart';
import 'download_manager.dart';
import 'favorites_manager.dart';
import 'fullscreen.dart';
import 'plugin/plugin.dart';
import 'plugin/utils.dart';
import '../localizations/localizations.dart';

class KiController extends Controller {
  Plugin plugin;
  KiController(JsScript script, this.plugin) : super(script);

  openBook(JsValue data) async {
    var d = jsValueToDart(data);
    enterFullscreenMode();
    await Navigator.of(state!.context).push(MaterialPageRoute(builder: (context) {
      return PictureViewer(
        data: RemotePictureData(
          plugin: plugin,
          bookKey: d["key"],
          list: d["list"],
          initializeIndex: d["index"],
        ),
      );
    }));
    exitFullscreenMode();
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
      var item = DownloadManager().add(BookInfo.fromData(jsValueToDart(data)), plugin);
      item?.start();
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

  getLastKey(String bookKey) {
    return plugin.storage.get("book:last:$bookKey");
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
      "getLastKey": JsFunction.ins((obj, argv) => obj.getLastKey(argv[0])),
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
      "clearNew": JsFunction.sta((argv) => FavoritesManager().clearNew(argv[0])),
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


class HeadlessWebView implements JsDispose {

  late BrowserWebViewController controller;
  JsValue? _onMessage;
  JsValue? _onLoadStart;
  JsValue? _onLoadEnd;
  JsValue? _onLoadError;

  JsValue? get onMessage => _onMessage;
  set onMessage(JsValue? val) {
    _onMessage?.release();
    _onMessage = val?..retain();
  }

  JsValue? get onLoadStart => _onLoadStart;
  set onLoadStart(JsValue? val) {
    _onLoadStart?.release();
    _onLoadStart = val?..retain();
  }

  JsValue? get onLoadEnd => _onLoadEnd;
  set onLoadEnd(JsValue? val) {
    _onLoadEnd?.release();
    _onLoadEnd = val?..retain();
  }

  JsValue? get onLoadError => _onLoadError;
  set onLoadError(JsValue? val) {
    _onLoadError?.release();
    _onLoadError = val?..retain();
  }

  HeadlessWebView(JsValue? options) {
    List<ResourceReplacement>? replacements;
    JsValue? rr = options?["resourceReplacements"];
    if (rr != null && rr.isArray == true) {
      replacements = [];
      for (int i = 0, t = rr["length"]; i < t; ++i) {
        var replacement = rr[i];
        replacements.add(ResourceReplacement(
          replacement["test"],
          replacement["resource"],
          replacement["mimeType"],
        ));
      }
    }

    controller = BrowserWebViewController(
      resourceReplacements: replacements,
    );
    controller.addEventHandler("message", (data) {
      if (_onMessage != null) {
        _onMessage?.call([dartToJsValue(_onMessage!.script, data)]);
      }
    });
    controller.onLoadStart.addListener(_loadStart);
    controller.onLoadEnd.addListener(_loadEnd);
    controller.onLoadError.addListener(_loadError);
  }

  void load(String url) => controller.loadUrl(url: url);

  @override
  void dispose() {
    controller.onLoadStart.removeListener(_loadStart);
    controller.onLoadEnd.removeListener(_loadEnd);
    controller.onLoadError.removeListener(_loadError);
    _onMessage?.release();
    _onLoadStart?.release();
    _onLoadEnd?.release();
    _onLoadError?.release();
    controller.dispose();
  }

  static Future<Map<String, List<String>>> getCookies(String url) async {
    var cookies = await BrowserWebViewController.getCookies(url);
    Map<String, List<String>> retults = {};
    for (var cookie in cookies) {
      List<String>? list = retults[cookie.name];
      if (list == null) {
        list = retults[cookie.name] = [];
      }
      list.add(cookie.value);
    }
    return retults;
  }

  void _loadStart() {
    _onLoadStart?.call([controller.onLoadStart.value]);
  }

  void _loadEnd() {
    _onLoadEnd?.call([controller.onLoadEnd.value]);
  }

  void _loadError() {
    var val = controller.onLoadError.value;
    _onLoadError?.call([val.first, val.second]);
  }

  dynamic eval(String script) {
    return controller.eval(script);
  }
}

ClassInfo headlessWebViewClass = ClassInfo<HeadlessWebView>(
    newInstance: (_, argv) => HeadlessWebView(argv.length > 0 ? argv[0] : null),
    functions: {
      "load": JsFunction.ins((obj, argv) => obj.load(argv[0])),
      "getCookies": JsFunction.sta((argv) => HeadlessWebView.getCookies(argv[0])),
      "eval": JsFunction.ins((obj, argv) => obj.eval(argv[0])),
    },
    fields: {
      "onmessage": JsField.ins(
        get: (obj) => obj.onMessage,
        set: (obj, val) => obj.onMessage = val,
      ),
      "onloadstart": JsField.ins(
        get: (obj) => obj.onLoadStart,
        set: (obj, val) => obj.onLoadStart = val,
      ),
      "onloadend": JsField.ins(
        get: (obj) => obj.onLoadEnd,
        set: (obj, val) => obj.onLoadEnd = val,
      ),
      "onfail": JsField.ins(
        get: (obj) => obj.onLoadError,
        set: (obj, val) => obj.onLoadError = val,
      ),
    }
);