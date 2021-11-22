
import 'dart:async';

import 'package:flutter/services.dart';

const MethodChannel _channel = const MethodChannel('native_main_thread');

typedef EventCallback = void Function(String name, String data);

class NativeMainThread {

  static NativeMainThread? _instance;

  static NativeMainThread get instance {
    if (_instance == null) {
      _instance = NativeMainThread._();
    }
    return _instance!;
  }

  Map<String, List<EventCallback>> _callbacks = {};

  NativeMainThread._() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case "event": {
          String name = call.arguments["name"];
          List<EventCallback>? list = _callbacks[name];
          if (list != null) {
            for (var callback in list) {
              callback(name, call.arguments["data"]);
            }
          }
          break;
        }
      }
    });
  }

  void addListener(String name, EventCallback callback) {
    List<EventCallback>? list = _callbacks[name];
    if (list == null) {
      list = [];
      _callbacks[name] = list;
    }
    list.add(callback);
  }

  void removeListener(String name, EventCallback callback) {
    List<EventCallback>? list = _callbacks[name];
    if (list != null) {
      list.remove(callback);
    }
  }
}
