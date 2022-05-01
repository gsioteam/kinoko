
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:flutter_dapp/extensions/storage.dart';
import '../../configs.dart';
import 'manga_loader.dart';
import 'package:xml_layout/status.dart';
import 'package:xml_layout/template.dart';
import 'package:xml_layout/xml_layout.dart';
import 'package:xml/xml.dart' as xml;
import 'package:fluttertoast/fluttertoast.dart';

class MessageException implements Exception {
  final String message;
  MessageException(this.message);

  @override
  String toString() => message;
}

class GitActionValue {
  String label;
  int loaded;
  int total;
  String? error;

  GitActionValue({
    required this.label,
    required this.loaded,
    required this.total,
    this.error,
  });

  GitActionValue copyWith({
    String? label,
    int? loaded,
    int? total,
    String? error,
  }) => GitActionValue(
    label: label ?? this.label,
    loaded: loaded ?? this.loaded,
    total: total ?? this.total,
    error: error ?? this.error,
  );

  bool get hasError => error != null;
}

class FakeNodeControl with NodeControl { }

class Extension {
  String icon;
  String index;

  Extension(this.icon, this.index);

  IconData? _iconData;

  IconData? getIconData() {
    if (_iconData == null) {
      Status status = Status({});
      NodeControl nodeControl = FakeNodeControl();
      Template template = Template(xml.XmlText(icon));
      var iter = template.generate(status, nodeControl);
      NodeData node = iter.first;
      _iconData = node.t<IconData>();
    }
    return _iconData;
  }
}

class PluginInformation {
  late String name;
  late String index;
  String? icon;
  late String processor;
  double? appBarElevation;
  late List<Extension> extensions;

  PluginInformation.fromData(dynamic json) {
    name = json['name'];
    index = json['index'];
    icon = json['icon'];
    extensions = [];
    var exs = json['extensions'];
    if (exs != null) {
      for (var ex in exs) {
        extensions.add(Extension(ex['icon'], ex['index']));
      }
    }
    processor = json['processor'];
    if (json['appbar_elevation'] is num)
      appBarElevation = (json['appbar_elevation'] as num).toDouble();
  }
}

class Plugin {

  String id;

  LocalStorage storage;
  DappFileSystem fileSystem;

  bool _test = false;
  bool get isTest => _test;

  PluginInformation? _information;
  PluginInformation? get information => _information;

  bool get isValidate => _information != null;


  Plugin(this.id, this.fileSystem, this.storage) {
    _setup();
  }

  void _setup() {
    try {
      var str = fileSystem.read('/config.json')!;
      var json = jsonDecode(str);

      _information = PluginInformation.fromData(json);
    } catch (e) {
    }
  }

  JsScript? _script;
  JsScript? get script {
    if (_script == null && isValidate) {
      _script = JsScript(
          fileSystems: [
            fileSystem,
          ],
      );
      Configs.instance.setupJS(_script!, this);
      _script!.global["showToast"] = (String msg) {
        Fluttertoast.showToast(msg: msg);
        print("[JS Toast]:\n$msg");
      };
      // _script!.addClass(processorClass);
    }
    return _script;
  }

  JsValue? _processorClass;
  JsValue makeProcessor(Processor processor) {
    if (isValidate) {
      String processorStr = information!.processor;
      if (processorStr[0] != '/') {
        processorStr = "/$processorStr";
      }
      if (_processorClass == null) {
        _processorClass = script!.run(processorStr + ".js");
      }
      if (_processorClass!.isConstructor) {
        JsValue jsProcessor = script!.bind(
            processor,
            classFunc: _processorClass!)..retain();
        return jsProcessor;
      } else {
        throw MessageException("wrong_script");
      }
    } else {
      throw MessageException("no_plugin");
    }
  }

  PluginLocalStorage? _localStorage;
  PluginLocalStorage get localStorage {
    if (_localStorage == null) {
      _localStorage = PluginLocalStorage(this);
    }
    return _localStorage!;
  }
}