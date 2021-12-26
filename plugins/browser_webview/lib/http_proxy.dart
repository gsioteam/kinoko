
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:http_multi_server/http_multi_server.dart';

import 'history_html.dart' as his;

import 'browser_webview.dart';

const String PROXY_PATH_HISTORY = "/history.html";
const String PROXY_PATH_REDIRECT = "/redirect";

class HttpProxyItem {
  final Pattern path;
  final FutureOr<Response> Function(Request request, Match match) onRequest;

  HttpProxyItem(this.path, this.onRequest);
}

class HttpProxy {
  static HttpProxy? _instance;

  late List<HttpProxyItem> items;

  factory HttpProxy() {
    if (_instance == null) {
      _instance = HttpProxy._();
    }
    return _instance!;
  }

  HttpProxy._() {
    items = [
      HttpProxyItem(PROXY_PATH_HISTORY, (request, _) {
        var uri = request.requestedUri;
        String? id = uri.queryParameters["id"];
        if (id != null) {
          var history = histories[int.tryParse(id)??0];
          if (history != null) {
            var html = his.html.replaceFirst(
                "{{0}}",
                jsonEncode(history.map((e) {
                  Map map = e.toData();
                  map["url"] = "$PROXY_PATH_REDIRECT?href=${Uri.encodeComponent(map["url"])}";
                  return map;
                }).toList())
            );
            return Response.ok(
                html,
                headers: {
                  "content-type": 'text/html; charset="utf-8"'
                }
            );
          }
        }
        return Response.notFound("${request.requestedUri.path} no resource");
      }),
      HttpProxyItem(PROXY_PATH_REDIRECT, (request, _) {
        var uri = request.requestedUri;
        String? href = uri.queryParameters["href"];
        if (href != null) {
          return Response.found(href);
        }
        return Response.notFound("${request.requestedUri.path} no resource");
      }),
    ];
    _ready = _setup();
  }

  late HttpServer _server;

  late Future<void> _ready;
  Future<void> get ready => _ready;
  Future<void> _setup() async {
    _server = await HttpMultiServer.loopback(0);
    shelf_io.serveRequests(_server, (request) {
      print("[${request.method}] ${request.requestedUri}");
      print(request.headers);
      var uri = request.requestedUri;

      var path = uri.path;
      for (var item in items) {
        var match = item.path.matchAsPrefix(path);
        if (match != null) {
          return item.onRequest(request, match);
        }
      }
      return Response.notFound("${request.requestedUri.path} no resource");
    });
  }

  Map<int, List<HistoryItem>> histories = {};

  void setHistory(int webId, List<HistoryItem> history) {
    histories[webId] = history;
  }

  String url([String? path]) {
    return "http://127.0.0.1:${_server.port}${path == null ? "/" : path}";
  }
}