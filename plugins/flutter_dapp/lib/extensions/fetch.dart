
import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dapp/extensions/extension.dart';
import 'package:flutter_dapp/src/flutter_dapp.dart';
import 'package:js_script/js_script.dart';

class JsRequest {
  Dio? dio;
  late String url;
  String? user;
  String? password;
  CancelToken? cancelToken;
  JsValue? _onState;
  int? timeout = 30000;
  int status = 0;
  String responseText = '';

  JsScript script;
  JsBuffer? buffer;

  Map<String, dynamic> headers = {};
  Headers? responseHeaders;

  JsRequest(this.script);

  void open(String method, String url, JsValue options) {
    dio = Dio(BaseOptions(
      method: method,
    ));
    this.url = url;
    this.user = options['user'];
    this.password = options['password'];
  }

  JsValue? get onState => _onState;
  set onState(JsValue? value) {
    _onState?.release();
    _onState = value?..retain();
  }

  void abort() {
    if (cancelToken != null) {
      cancelToken!.cancel();
      onState?.call(['abort']);
      _onEnd();
    }
  }

  void send(JsValue body) {
    if (dio == null) {
      throw Exception("Request not open");
    }
    cancelToken = CancelToken();
    dynamic rawBody;
    if (body['type'] == 'string') {
      rawBody = body['data'];
    }
    var future = dio!.requestUri<ResponseBody>(
      Uri.parse(url),
      cancelToken: cancelToken,
      options: Options(
        headers: headers,
        responseType: ResponseType.stream,
      ),
      onReceiveProgress: (count, total) {
        onState?.call(['progress', count, total]);
      },
      data: rawBody,
    );
    if (timeout != null) {
      future = future.timeout(Duration(milliseconds: timeout!), onTimeout: () {
        onState?.call(['timeout']);
        throw TimeoutException("timeout");
      });
    }
    future.then((value) {
      _onResponse(value);
    }).catchError((e, stack) {
      _onError(e);
    });
    onState?.call(['loadstart']);
  }

  void _onResponse(Response<ResponseBody> response) async {
    status = response.statusCode ?? 0;
    responseHeaders = response.headers;
    onState?.call(['headers', response.realUri.toString()]);
    List<Uint8List> chunks = [];
    int length = 0;
    await for (var chunk in response.data!.stream) {
      chunks.add(chunk);
      length += chunk.length;
    }
    buffer = script.newBuffer(length);
    int offset = 0;
    for (var chunk in chunks) {
      buffer!.fill(chunk, offset);
      offset += chunk.length;
    }
    onState?.call(['load']);
    _onEnd();
  }

  void _onError(e) {
    onState?.call(['error', e.toString()]);
    _onEnd();
  }

  void _onEnd() {
    onState?.call(['loadend']);
    _cleanUp();
  }

  void _cleanUp() {
    cancelToken = null;
    dio?.close();
    dio = null;
    onState = null;
  }

  void setRequestHeader(String key, String value) {
    var val = headers[key];
    if (val is String) {
      headers[key] = [val, value];
    } else if (val is List) {
      val.add(value);
    } else {
      headers[key] = value;
    }
  }

  String? getAllResponseHeaders() {
    return responseHeaders?.toString();
  }

  String? getResponseHeader(String name) {
    return responseHeaders?.value(name);
  }
}

ClassInfo requestClass = ClassInfo<JsRequest>(
    name: 'Request',
    newInstance: (script, argv) => JsRequest(script),
    functions: {
      "open": JsFunction.ins((obj, argv) => obj.open(argv[0], argv[1], argv[2])),
      "abort": JsFunction.ins((obj, argv) => obj.abort()),
      "send": JsFunction.ins((obj, argv) => obj.send(argv[0])),
      "setRequestHeader": JsFunction.ins((obj, argv) => obj.setRequestHeader(argv[0], argv[1])),
      "getAllResponseHeaders": JsFunction.ins((obj, argv) => obj.getAllResponseHeaders()),
      "getResponseHeader": JsFunction.ins((obj, argv) => obj.getResponseHeader(argv[0])),
    },
    fields: {
      "onState": JsField.ins(
        get: (obj) => obj.onState,
        set: (obj, v) => obj.onState = v,
      ),
      "buffer": JsField.ins(
        get: (obj) => obj.buffer,
      ),
      "timeout": JsField.ins(
        get: (obj) => obj.timeout,
        set: (obj, v) => obj.timeout = v,
      ),
      "status": JsField.ins(
        get: (obj) => obj.status,
      ),
      "response": JsField.ins(
        get: (obj) => obj.buffer,
      )
    }
);

///
/// Contains `fetch`, `XMLHTTPRequest` functions.
class Fetch extends Extension {
  @override
  Future<String> loadCode(BuildContext context) {
    return rootBundle.loadString("packages/flutter_dapp/js_env/fetch.min.js");
  }

  @override
  void setup(JsScript script) {
    script.addClass(requestClass);
  }

}