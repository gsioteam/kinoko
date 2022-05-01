
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:browser_webview/http_proxy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;

import 'user_script.dart';
import 'messenger_js.dart' as messenger;

export 'user_script.dart';

class HistoryItem {
  late String url;
  String? title;
  bool current = false;

  HistoryItem.from(Map data) {
    url = data["url"];
    title = data["title"];
    current = data["current"] == true;
  }

  Map toData() => {
    "url": url,
    "title": title ?? "",
    "current": current
  };

  HistoryItem({
    required this.url,
    this.title,
    this.current = false
  });
}

class Cookie {
  String name;
  String value;

  Cookie({
    required this.name,
    required this.value,
  });
}

class EventListenable<T> extends ValueListenable<T> {
  Set<VoidCallback> _listeners = Set();

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  EventListenable(this._value);
  T _value;
  @override
  T get value => _value;

  void emit(T value) {
    _value = value;
    for (var listener in _listeners) {
      listener();
    }
  }

}

class TwinValue<T1, T2> {
  T1 first;
  T2 second;

  TwinValue(this.first, this.second);

  @override
  bool operator ==(Object other) {
    if (other is TwinValue<T1, T2>) {
      return first == other.first && second == other.second;
    }
    return false;
  }

  @override
  int get hashCode {
    return 0x98333333 | first.hashCode << 8 | second.hashCode;
  }
}

class DownloadInformation {
  String url;
  String method;
  Map headers;
  String filename;

  DownloadInformation({
    required this.url,
    required this.method,
    required this.headers,
    required this.filename
  });
}

class ResourceReplacement {
  String test;
  String? mimeType;
  String resource;

  ResourceReplacement(this.test, this.resource, [this.mimeType]);
}

typedef BrowserDownloadCallback = Future<bool> Function(DownloadInformation info);
typedef BrowserWindowCreator = Future<bool> Function(String url, BrowserWebViewController Function() creator);
typedef BrowserOpenSafariCallback = Future<bool> Function(String url);

class BrowserWebViewController {
  static const MethodChannel _channel =
  const MethodChannel('browser_webview');
  static bool _isSetup = false;

  static Map<int, BrowserWebViewController> _controllers = {};
  static int _idCounter = 0x9002;

  int _id;
  int get id => _id;

  final EventListenable<String> url = EventListenable("");
  final EventListenable<String> title = EventListenable("");
  final EventListenable<double> progress = EventListenable(0);

  final EventListenable<String> onLoadStart = EventListenable("");
  final EventListenable<String> onLoadEnd = EventListenable("");
  final EventListenable<TwinValue<String, String>> onLoadError = EventListenable(TwinValue("", ""));
  BrowserDownloadCallback? onDownload;
  BrowserWindowCreator? onCreateWindow;
  BrowserOpenSafariCallback? onOpenSafari;
  VoidCallback? onGrab;
  Map<String, List<ScriptEventHandler>> _eventHandlers = {};

  BrowserWebViewState? currentState;

  late Future _ready;
  Future get ready => _ready;

  static Future<void> setup() async {
    await HttpProxy().ready;
  }

  BrowserWebViewController({
    String? initializeUrl,
    bool allowsBackForwardGestures = false,
    List<HistoryItem>? history,
    List<UserScript>? scripts,
    List<ResourceReplacement>? resourceReplacements,
  }) : _id = _idCounter++ {
    if (!_isSetup) {
      _isSetup = true;
      _channel.setMethodCallHandler(_channelHandler);
    }
    _controllers[_id] = this;
    if (history != null) {
      var proxy = HttpProxy();
      proxy.setHistory(_id, history);
      initializeUrl = proxy.url("$PROXY_PATH_HISTORY?id=$_id");
    }
    List<UserScript> _scripts = [
      UserScript(
        script: messenger.js,
        arguments: {
          "on_send": "POST_MESSAGE"
        },
        position: InjectPosition.start,
      ),
    ];
    if (scripts != null) {
      _scripts.addAll(scripts);
    }
    _ready = _channel.invokeMethod("init", {
      "id": _id,
      "url": initializeUrl,
      "allowsBackForwardGestures": allowsBackForwardGestures,
      "scripts": _scripts.map((e) => e.toData()).toList(),
      "resourceReplacements": resourceReplacements?.map((e) => {
        "test": e.test,
        "resource": e.resource,
        "mimeType": e.mimeType,
      }).toList(),
    });

    if (initializeUrl != null) {
      url.emit(initializeUrl);
    }
  }

  BrowserWebViewController._createWindow(String initializeUrl) : _id = _idCounter++ {
    url.emit(initializeUrl);
    _controllers[_id] = this;
    _ready = SynchronousFuture(null);
  }

  void dispose() {
    _controllers.remove(_id);
    _channel.invokeMethod("dispose", {
      "id": _id
    });
  }

  void addEventHandler(String event, ScriptEventHandler handler) {
    var lis = _eventHandlers[event];
    if (lis == null) {
      _eventHandlers[event] = lis = [];
    }
    lis.add(handler);
  }

  void removeEventHandler(String event, ScriptEventHandler handler) {
    _eventHandlers[event]?.remove(handler);
  }

  Future<void> loadUrl({
    required String url,
  }) async {
    await _invoke("loadUrl", {
      "id": _id,
      "url": url,
    });
  }
  
  Future<List<HistoryItem>> getHistoryList() async {
    dynamic result = await _invoke("getHistoryList", {
      "id": _id
    });
    List list = result["list"];
    List<HistoryItem> items = [];
    for (var data in list) {
      HistoryItem item = HistoryItem.from(data);
      Uri uri = Uri.parse(item.url);
      if (uri.host == "127.0.0.1") {
        if (uri.path == PROXY_PATH_HISTORY) {

        } else if (uri.path == PROXY_PATH_REDIRECT) {
          var url = uri.queryParameters["href"];
          if (url != null) {
            item.url = url;
            items.add(item);
          }
        } else {
          items.add(item);
        }
      } else {
        items.add(item);
      }
    }
    return items;
  }

  Future<void> postMessage(String method, [dynamic arguments]) async {
    await _invoke('postMessage', {
      "id": _id,
      "method": method,
      "data": arguments,
    });
  }

  Future<dynamic> _invoke(String method, [dynamic arguments]) async {
    var result = await _channel.invokeMethod(method, arguments);
    if (result is Map && result.containsKey("error")) {
      throw Exception(result["error"]);
    }
    return result;
  }
  
  Future<String> takeCapture({
    double? width
  }) async {
    var result = await _channel.invokeMethod<Map>("takeCapture", {
      "id": _id,
      "width": width,
    });
    if (result!.containsKey("error")) {
      throw Exception(result["error"]);
    } else {
      return result["path"];
    }
  }

  Future<void> reload() async {
    await _channel.invokeMethod<Map>("reload", {
      "id": _id,
    });
  }

  Future<void> stop() async {
    await _channel.invokeMethod<Map>("stop", {
      "id": _id,
    });
  }

  Future<void> goBack() async {
    await _channel.invokeMethod<Map>("goBack", {
      "id": _id,
    });
  }

  Future<void> goForward() async {
    await _channel.invokeMethod<Map>("goForward", {
      "id": _id,
    });
  }

  Future eval(String script) async {
    dynamic data = await _channel.invokeMethod("eval", {
      "id": _id,
      "script": script,
    });
    if (data is Map && data['\$json_parse'] == true) {
      data = jsonDecode(data['result']);
    }
    return data;
  }
  
  Future<void> setDownloadDetector({
    List<String>? extensions,
    List<String>? mimeTypes,
  }) async {
    await _channel.invokeMethod("setDownloadDetector", {
      "id": _id,
      "extensions": extensions,
      "mime_types": mimeTypes,
    });
  }

  static Future<void> clear(String type) async {
    await _channel.invokeMethod("clear", {
      "type": type,
    });
  }

  Future<void> setEnablePullDown(bool enable) async {
    await _channel.invokeMethod("setEnablePullDown", {
      "id": _id,
      "value": enable,
    });
  }

  Future<void> setScrollEnabled(bool enable) async {
    await _channel.invokeMethod("setScrollEnabled", {
      "id": _id,
      "value": enable,
    });
  }

  Future<void> makeOffscreen() async {
    await _channel.invokeMethod("makeOffscreen", {
      "id": _id,
    });
  }

  static Future<List<Cookie>> getCookies(String url) async {
    List<Cookie> list = [];
    var data = await _channel.invokeMethod('getCookies', {
      "url": url,
    });
    for (var cData in data['cookies']) {
      String name = cData['name'];
      String value = cData['value'];
      list.add(Cookie(
          name: name.trim(),
          value: value.trim(),
      ));
    }
    return list;
  }

  static Future _channelHandler(MethodCall call) async {
    switch (call.method) {
      case 'urlChanged': {
        var controller = _controllers[call.arguments["id"]];
        if (controller != null) {
          String? url = call.arguments["url"];
          if (url != null) {
            var uri = Uri.parse(url);
            if (uri.host == "127.0.0.1") {
              if (uri.path == PROXY_PATH_HISTORY) {
                url = "";
              } else if (uri.path == PROXY_PATH_REDIRECT) {
                url = uri.queryParameters["href"];
              }
            }
          }
          if (url?.isNotEmpty == true) {
            controller.url.emit(url!);
          }
        }
        break;
      }
      case 'titleChanged': {
        var controller = _controllers[call.arguments["id"]];
        if (controller != null) {
          controller.title.emit(call.arguments["title"]);
        }
        break;
      }
      case 'onAlert': {
        var controller = _controllers[call.arguments["id"]];
        if (controller != null) {
          await controller.currentState?.onAlert(call.arguments["message"]);
        }
        break;
      }
      case 'onConfirm': {
        var controller = _controllers[call.arguments["id"]];
        if (controller != null) {
          return await controller.currentState?.onConfirm(call.arguments["message"]);
        }
        break;
      }
      case 'onCreateWindow': {
        var controller = _controllers[call.arguments["id"]];
        if (controller != null) {
          Future onCreateWindow(String url) async {
            if (controller.onCreateWindow != null) {
              BrowserWebViewController? newController;
              BrowserWebViewController creator() {
                newController = BrowserWebViewController._createWindow(url);
                return newController!;
              }
              bool ret = await controller.onCreateWindow!(url, creator);
              if (ret) {
                if (newController == null)
                  newController = creator();
                return {
                  "id": newController!._id
                };
              }
            }
          }
          return await onCreateWindow(call.arguments["url"]);
        }
        break;
      }
      case 'onProgress': {
        var controller = _controllers[call.arguments["id"]];
        if (controller != null) {
          controller.progress.emit(call.arguments["progress"]);
        }
        break;
      }
      case 'loadStart': {
        var controller = _controllers[call.arguments["id"]];
        if (controller != null) {
          controller.onLoadStart.emit(call.arguments["url"]);
        }
        break;
      }
      case 'loadEnd': {
        var controller = _controllers[call.arguments["id"]];
        if (controller != null) {
          controller.onLoadEnd.emit(call.arguments["url"]);
        }
        break;
      }
      case 'loadError': {
        var controller = _controllers[call.arguments["id"]];
        if (controller != null) {
          controller.onLoadError.emit(TwinValue(
            call.arguments["url"],
            call.arguments["error"]
          ));
        }
        break;
      }
      case 'onEvent': {
        var controller = _controllers[call.arguments["id"]];
        if (controller != null) {
          var event = call.arguments["event"];
          var json = call.arguments["json"];
          var data = json != null ? jsonDecode(json) : call.arguments["data"];
          var lis = controller._eventHandlers[event];
          if (lis != null && lis.length > 0) {
            List.from(lis).forEach((fn) {
              fn.call(data);
            });
          } else {
            print('no handler $event');
          }
        }
        break;
      }
      case 'onDownload': {
        var controller = _controllers[call.arguments["id"]];
        if (controller != null) {
          String url = call.arguments['url'];
          String method = call.arguments['method'];
          Map headers = call.arguments['headers'];
          var uri = Uri.parse(url);
          String filename = call.arguments['filename'] ?? Uri.decodeComponent(path.basename(uri.path));

          return controller.onDownload?.call(DownloadInformation(
              url: url,
              method: method,
              headers: headers,
              filename: filename
          ));
        }
        break;
      }
      case 'onOverDrag': {
        var controller = _controllers[call.arguments["id"]];
        if (controller != null) {
          controller.currentState?.onOverDrag();
        }
        break;
      }
      case 'onOpenInBrowser': {
        var controller = _controllers[call.arguments["id"]];
        if (controller != null) {
          String url = call.arguments['url'];
          return controller.onOpenSafari?.call(url);
        }
        break;
      }
      case 'onGrab': {
        var controller = _controllers[call.arguments["id"]];
        if (controller != null) {
          return controller.onGrab?.call();
        }
        break;
        break;
      }
    }
  }
}

class BrowserWebView extends StatefulWidget {
  final BrowserWebViewController controller;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final Future<void> Function(BuildContext context, String message)? onAlert;
  final Future<bool> Function(BuildContext context, String message)? onConfirm;
  final VoidCallback? onOverDrag;
  final bool enablePullDown;

  BrowserWebView({
    Key? key,
    required this.controller,
    this.gestureRecognizers,
    this.onAlert,
    this.onConfirm,
    this.onOverDrag,
    this.enablePullDown = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => BrowserWebViewState();

}

class BrowserWebViewState extends State<BrowserWebView> {

  static const String viewType = "browser_web_view";

  @override
  Widget build(BuildContext context) {
    Map params = {
      "id": widget.controller._id
    };
    if (Platform.isAndroid) {
      return PlatformViewLink(
        viewType: viewType,
        surfaceFactory:
            (BuildContext context, PlatformViewController controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: widget.gestureRecognizers ?? const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (PlatformViewCreationParams platformParams) {
          return PlatformViewsService.initSurfaceAndroidView(
            id: platformParams.id,
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: params,
            creationParamsCodec: StandardMessageCodec(),
          )
            ..addOnPlatformViewCreatedListener(platformParams.onPlatformViewCreated)
            ..create();
        },
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: widget.gestureRecognizers,
      );
    } else {
      throw Exception("Not support platform");
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller.currentState = this;
    widget.controller.setEnablePullDown(widget.enablePullDown);
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.currentState = null;
  }


  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.enablePullDown != oldWidget.enablePullDown) {
      widget.controller.setEnablePullDown(widget.enablePullDown);
    }
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.currentState = null;
      widget.controller.currentState = this;
    }
  }

  Future<void> onAlert(String message) async {
    await widget.onAlert?.call(context, message);
  }

  Future<bool> onConfirm(String message) async {
    return await widget.onConfirm?.call(context, message) ?? false;
  }

  void onOverDrag() {
    widget.onOverDrag?.call();
  }
}