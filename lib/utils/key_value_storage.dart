
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:glib/main/models.dart';

typedef KeyValueDecoder<T> = T Function(String json);
typedef KeyValueEncoder<T> = String Function(T data);


T _defaultDecoder<T>(String json) {
  if (T == Map) {
    if (json.isEmpty) {
      return {} as T;
    } else {
      return Map.from(jsonDecode(json)) as T;
    }
  } else if (T == List) {
    if (json.isEmpty) {
      return [] as T;
    } else {
      return List.from(jsonDecode(json)) as T;
    }
  } else {
    throw Exception("$T is not supported.");
  }
}

String _defaultEncoder<T>(T data) {
  return jsonEncode(data);
}

class KeyValueStorage<T> with ChangeNotifier {
  late T _data;
  final String key;
  late KeyValueDecoder<T> _decoder;
  late KeyValueEncoder<T> _encoder;

  KeyValueStorage({
    required this.key,
    KeyValueDecoder<T>? decoder,
    KeyValueEncoder<T>? encoder,
  }) {
    _decoder = decoder == null ? _defaultDecoder : decoder;
    _encoder = encoder == null ? _defaultEncoder : encoder;
    _data = _decoder(KeyValue.get(key));
  }

  void update() {
    KeyValue.set(key, _encoder(_data));
    notifyListeners();
  }

  T get data => _data;
  set data(T value) {
    if (_data != value) {
      _data = value;
      update();
    }
  }
}