
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:glib/glib.dart';
import 'package:glib/utils/bit64.dart';
import 'package:kinoko/utils/local_storage.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:yaml/yaml.dart';
import 'key_value_storage.dart';
import 'plugin/plugin.dart';
import 'plugin/io_filesystem.dart';

class PluginInfo {
  String title;
  String? icon;
  String src;
  String? branch;
  bool? ignore;

  PluginInfo({
    required this.title,
    this.icon,
    required this.src,
    this.branch,
    this.ignore,
  });

  PluginInfo.fromData(Map data) :
      title = data["title"],
      icon = data["icon"],
      src = data["src"],
      branch = data["branch"],
      ignore = data["ignore"];

  Map toData() {
    return {
      "title": title,
      "icon": icon,
      "src": src,
      "branch": branch,
      "ignore": ignore,
    };
  }
}

const String _pluginsKey = "plugins";
const String _lastUpdateKey = "plugins_last_update";
const String _addedKey = "plugins_added";

class PluginsManager {
  static late Directory _root;

  static PluginsManager? _instance;
  static PluginsManager get instance {
    if (_instance == null) {
      _instance = PluginsManager._();
    }
    return _instance!;
  }

  late KeyValueStorage<List<PluginInfo>> _plugins;
  KeyValueStorage<List<PluginInfo>> get plugins => _plugins;

  KeyValueStorage<DateTime> _lastUpdate = KeyValueStorage(
    key: _lastUpdateKey,
    decoder: (str) {
      return DateTime.fromMillisecondsSinceEpoch(int.tryParse(str) ?? 0);
    },
    encoder: (time) {
      return time.millisecondsSinceEpoch.toString();
    }
  );

  DateTime get lastUpdate => _lastUpdate.data;
  set lastUpdate(date) => _lastUpdate.data = date;

  KeyValueStorage<List> _added = KeyValueStorage(key: _addedKey);

  late Future<void> _ready;
  Future<void> get ready => _ready;

  PluginsManager._() {
    _plugins = KeyValueStorage(
      key: _pluginsKey,
      decoder: (String json) {
        if (json.isEmpty) return [];
        List list = jsonDecode(json);
        List<PluginInfo> ret = [];
        for (var data in list) {
          ret.add(PluginInfo.fromData(data));
        }
        return ret;
      },
      encoder: (List<PluginInfo> plugins) {
        List data = [];
        for (var plugin in plugins) {
          data.add(plugin.toData());
        }
        return jsonEncode(data);
      }
    );
    _ready = _setup();
  }

  Future<void> _setup() async {
    Directory dir = await path_provider.getApplicationSupportDirectory();
    _root = Directory("${dir.path}/plugins");
  }

  String _prev = "";

  void update(List json, Uint8List pubKey, [bool reset = true]) {
    if (reset) _prev = "";
    for (var d in json) {
      try {
        var body = d['body'];
        var bodyData = loadYaml(body);
        String token = bodyData["token"];
        var info = PluginInfo.fromData(bodyData);

        var ret = tokenVerify(token, info.src, _prev, pubKey);
        if (ret) {
          _prev = token;
          if (_added.data.contains(info.src)) {
            continue;
          }
          _added.data.add(info.src);
          _added.update();

          add(info);
        } else {
        }
      } catch (e) {
        print("Error $e");
      }

    }
  }

  void remove(PluginInfo pluginInfo) {
    _plugins.data.removeWhere((el) => el.src == pluginInfo.src);
    _plugins.update();
  }

  bool add(PluginInfo pluginInfo) {
    bool has = false;
    for (var item in _plugins.data) {
      if (item.src == pluginInfo.src) {
        has = true;
        break;
      }
    }
    if (has) {
      return false;
    }
    _plugins.data.add(pluginInfo);
    _plugins.update();

    return true;
  }

  String calculatePluginID(String src) {
    return Bit64.encodeString(src);
  }

  Plugin? makePlugin(String src) {
    String id = calculatePluginID(src);

    File configFile = File("${_root.path}/$id/config.json");
    if (configFile.existsSync()) {
      return Plugin(id, IOFileSystem(Directory("${_root.path}/$id")), DataLocalStorage(id));
    }
    return null;
  }
}