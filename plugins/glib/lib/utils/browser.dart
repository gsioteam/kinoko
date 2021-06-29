
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:glib/core/callback.dart';
import 'package:glib/core/core.dart';
import 'package:glib/core/gmap.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:yaml/yaml.dart';

class Browser extends Base {

  static GlobalKey globalKey;
  InAppWebViewController controller;

  static reg() {
    Base.reg(Browser, "gs::DartBrowser", Base)
      ..constructor = ((id) => Browser().setID(id));
  }

  Uri uri;
  bool hidden;
  List<String> cookieList = [];

  bool complete = false;

  Callback onComplete;
  String error;
  String userAgent;

  @override
  void initialize() {
    super.initialize();

    on("setup", setup);
    on("start", start);
    on("setOnComplete", setOnComplete);
    on("getError", getError);
    on("setUserAgent", setUserAgent);
  }

  @override
  void destroy() {
    super.destroy();
    onComplete?.release();
  }

  void setOnComplete(Callback callback) {
    onComplete?.release();
    onComplete = callback?.control();
  }

  void setUserAgent(String ua) {
    userAgent = ua;
  }

  void setup(String url, String rules, bool hidden) {
    this.uri = Uri.parse(url);
    this.hidden = hidden;
    var node = loadYamlNode(rules);
    if (node is YamlMap) {
      var cookie = node.nodes["cookie"];
      if (cookie is YamlScalar)
        cookieList = [cookie.value];
      else if (cookie is YamlList) {
        cookieList = List<String>.from(cookie.nodes.map((e) => e.value));
      }
    }
    control();
  }

  Widget buildWebView(VoidCallback callback) {
    return InAppWebView(
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          userAgent: userAgent ?? "",
          javaScriptEnabled: true,
        )
      ),
      initialUrlRequest: URLRequest(url: uri),
      onWebViewCreated: (controller) {
        this.controller = controller;
      },
      onLoadStop: (controller, uri) {
        callback();
      },
      onLoadStart: (controller, uri) {
        callback();
      },
    );
  }

  Widget buildPosition(Widget child) {
    if (hidden) {
      return Positioned(
        child: Opacity(
          child: child,
          opacity: 0,
        ),
        left: 0,
        top: 0,
        width: 10,
        height: 10,
      );
    } else {
      return Positioned(
        child: child,
        left: 0,
        right: 0,
        top: 0,
        bottom: 0,
      );
    }
  }

  void start() async {
    if (globalKey != null) {
      CookieManager cookieManager = CookieManager.instance();
      await cookieManager.deleteAllCookies();

      runTask().then((map) {
        entry?.remove();
        onComplete.invoke([GMap.allocate(map).release()]);
      }).timeout(Duration(seconds: 15), onTimeout: () {
        entry?.remove();
        error = "timeout";
        onComplete.invoke([]);
      });
    }
  }

  OverlayEntry entry;

  Future<Map<String, dynamic>> runTask() {
    Completer<Map<String, dynamic>> completer = Completer();
    entry = OverlayEntry(builder: (context) {
      return buildPosition(
          buildWebView(() async {
            var map = await testRules(entry);
            if (map != null) {
              completer.complete(map);
            }
          })
      );
    });
    Overlay.of(globalKey.currentContext).insert(entry);
    return completer.future;
  }

  Future<Map<String, dynamic> > testRules(OverlayEntry entry) async {
    CookieManager cookieManager = CookieManager.instance();
    bool found = false;

    Map<String, dynamic> map = {};
    final gotCookies = await cookieManager.getCookies(url: uri);
    for (var item in gotCookies) {
      if (cookieList.contains(item.name)) {
        map[item.name] = item.value;
        found = true;
      }
    }

    if (found) {
      if (complete) return null;
      complete = true;
      String userAgent = await controller.evaluateJavascript(source: "navigator.userAgent");
      map["user-agent"] = jsonDecode(userAgent);
      return map;
    }
    return null;
  }

  String getError() {
    return error;
  }
}