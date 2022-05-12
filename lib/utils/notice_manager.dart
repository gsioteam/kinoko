
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:kinoko/utils/key_value_storage.dart';

const String _URL = "https://raw.githubusercontent.com/gsioteam/kinoko/master/docs/notice/{0}.md";

class NoticeValue {
  final bool newContent;
  final String content;
  final String url;

  NoticeValue({
    required this.newContent,
    required this.content,
    required this.url,
  });

  NoticeValue.from(Map data) :
        newContent = data["newContent"] ?? false,
        content = data["content"] ?? "",
        url = data["url"] ?? "";

  Map toData() {
    return {
      "newContent": newContent,
      "content": content,
      "url": url,
    };
  }

}

class NoticeData {
  String title;
  String markdown;
  Uri uri;

  NoticeData(this.title, this.markdown, this.uri);
}

class NoticeManager extends ChangeNotifier {
  static NoticeManager? _instance;

  static NoticeManager instance() {
    if (_instance == null) {
      _instance = NoticeManager._();
    }
    return _instance!;
  }

  KeyValueStorage<Map> _mapStorage = KeyValueStorage(
    key: "notice_manager_data",
    decoder: (text) {
        return text.isEmpty ? {} : Map.from(jsonDecode(text));
    },
    encoder: (map) {
      return jsonEncode(map);
    }
  );

  late NoticeValue value;
  NoticeManager._() {
    value = NoticeValue.from(_mapStorage.data);
  }

  check(BuildContext context) async {
    Locale locale = Localizations.localeOf(context);
    String url = _URL.replaceFirst("{0}", locale.languageCode);
    String? content = await fetch(url);
    if (content == null) {
      url = _URL.replaceFirst("{0}", "en");
      content = await fetch(url);
    }

    if (content == null) {
      value = NoticeValue(
        newContent: false,
        content: "",
        url: url
      );
      notifyListeners();
    } else {
      if (value.content != content) {
        value = NoticeValue(
          newContent: true,
          content: content,
          url: url
        );
        notifyListeners();
      }
    }
  }

  Future<String?> fetch(String url) async {
    try {
      Request request = Request("GET", Uri.parse(url));
      StreamedResponse res = await request.send();
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return await res.stream.bytesToString();
      }
    } catch (e) {

    }
    return null;
  }

  NoticeData? displayData() {
    if (value.content.isEmpty) {
      return null;
    }
    var list = value.content.split("\n");

    var tList = [];
    var rest = [];
    var isTitle = true;
    for (var line in list) {
      if (isTitle) {
        if (line.startsWith("--------")) {
          isTitle = false;
          continue;
        }
        tList.add(line);
      } else {
        rest.add(line);
      }
    }

    return NoticeData(tList.join("\n").trim(), rest.join("\n").trim(), Uri.parse(value.url));
  }
}