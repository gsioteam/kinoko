import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:glib/core/callback.dart';

import '../core/core.dart';
import '../core/data.dart';
import '../core/gmap.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:dio/dio.dart';

enum BodyType {
  Raw,
  Mutilpart,
  UrlEncode
}

class Request extends Base {
  static reg() {
    Base.reg(Request, "gs::DartRequest", Base)
        ..constructor = ((id) => Request().setID(id));
  }

  Uint8List body;
  Dio dio;
  int uploadNow;
  int uploadTotal;
  int downloadNow;
  int downloadTotal;

  int _timeout;

  bool _canceled = false, _started = false;
  StreamSubscription<List<int>> _subscription;
  Uint8List responseBody;
  GMap responseHeader;
  String _error;

  int statusCode = 0;

  Callback onUploadProgress;
  Callback onDownloadProgress;
  Callback onComplete;
  Callback onResponse;

  String responseURL;

  bool cacheResponse = false;

  Request();

  @override
  initialize() {
    super.initialize();
    on("setup", setup);
    on("release", _release);
    on("setHeader", setHeader);
    on("setBody", setBody);
    on("setOnUploadProgress", setOnUploadProgress);
    on("setOnProgress", setOnProgress);
    on("setOnComplete", setOnComplete);
    on("setOnResponse", setOnResponse);
    on("getUploadNow", getUploadNow);
    on("getUploadTotal", getUploadTotal);
    on("getDownloadNow", getDownloadNow);
    on("getDownloadTotal", getDownloadTotal);
    on("setTimeout", setTimeout);
    on("getError", getError);
    on("cancel", cancel);
    on("start", start);
    on("setCacheResponse", setCacheResponse);

    on("getResponseBody", getResponseBody);
    on("getStatusCode", getStatusCode);
    on("getResponseHeaders", getResponseHeaders);
    on("getResponseUrl", getResponseUrl);
  }

  _release() {
    release();
  }
  Uri uri;
  BodyType type;

  setup(String method, String url, int type) {
    uri = Uri.parse(url);
    this.type = BodyType.values[type];

    dio = Dio(
      BaseOptions(
        method: method,
        responseType: ResponseType.stream
      )
    )
    //   ..httpClientAdapter = Http2Adapter(ConnectionManager(
    //   idleTimeout: 10000,
    //   onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
    // ))
    ;

    control();
  }

  Data getResponseBody() {
    return Data.fromByteBuffer(responseBody.buffer).release();
  }

  GMap getResponseHeaders() => responseHeader;

  String responseUrl;
  String getResponseUrl() => responseURL;

  int getStatusCode() => statusCode;

  Map<String, String> headers = {};
  setHeader(String name, String value) {
    headers[name] = value;
  }

  setBody(Pointer ptr, int length) {

    Uint8List buf = ptr.cast<Uint8>().asTypedList(length);
    // req.body = str;
    body = new Uint8List(buf.length);
    body.setAll(0, buf);
  }

  setOnUploadProgress(Callback cb) {
    onUploadProgress?.release();
    onUploadProgress = cb?.control();
  }

  setOnProgress(Callback cb) {
    onDownloadProgress?.release();
    onDownloadProgress = cb.control();
  }

  setOnComplete(Callback cb) {
    onComplete?.release();
    onComplete = cb?.control();
  }

  setOnResponse(Callback cb) {
    onResponse?.release();
    onResponse = cb?.control();
  }

  setTimeout(int timeout) {
    _timeout = timeout;
  }

  uploadProgress(int byte, int total) {
    uploadNow = byte;
    uploadTotal = total;
    if (onUploadProgress != null) {
      onUploadProgress.invoke([byte, total]);
    }
  }

  getUploadNow() {
    return uploadNow;
  }

  getUploadTotal() {
    return uploadTotal;
  }

  getDownloadNow() {
    return downloadNow;
  }

  getDownloadTotal() {
    return downloadTotal;
  }

  setCacheResponse(bool cr) {
    cacheResponse = cr;
  }

  start() async {
    if (_started) return;
    _started = true;
    try {
      if (cacheResponse) {
        Stream<FileResponse> stream = DefaultCacheManager().getFileStream(uri.toString(), headers: headers, withProgress: true);
        await for (FileResponse res in stream) {
          if (res is DownloadProgress) {
            downloadTotal = res.totalSize;
            downloadNow = res.downloaded;
            if (onDownloadProgress != null) onDownloadProgress.invoke([downloadNow, downloadTotal]);
          } else if (res is FileInfo) {
            responseBody = await res.file.readAsBytes();
          }
        }
      } else {
        Response<ResponseBody> res = await dio.requestUri(
          uri,
          options: Options(
            headers: headers,
            followRedirects: true,
            requestEncoder: (request, options) {
              return options.data;
            },
            validateStatus: (status) {
              return status < 500;
            }
          ),
          data: body ?? Uint8List(0)
        );
        if (_canceled) return;
        downloadTotal = int.tryParse(res.headers.value(Headers.contentLengthHeader) ?? "0") ?? 0;
        statusCode = res.statusCode;
        responseURL = res.realUri.toString();
        responseHeader?.release();
        responseHeader = GMap.allocate({});
        res.headers.forEach((key, value) {
          responseHeader[key] = value;
        });
        onResponse?.invoke([]);

        downloadNow = 0;
        List<int> receiveBody = [];
        _subscription = res.data.stream.listen((value) {
          downloadNow += value.length;
          receiveBody.addAll(value);
          onDownloadProgress?.invoke([downloadNow, downloadTotal]);
        });
        await _subscription.asFuture().timeout(Duration(milliseconds: _timeout ?? 30000), onTimeout: () {
          if (!_canceled) {
            throw new Exception("Timeout");
          }
        });
        responseBody = Uint8List.fromList(receiveBody);
      }

    } catch (e) {
      _error = e.toString();
      print("Error $_error");
      if (onComplete != null) onComplete?.invoke([]);
      else print("Error complete $onComplete  on ($this) " + _error);
      cancel();
    }

    if (onComplete != null) {
      onComplete.invoke([]);
    }
  }

  cancel() {
    _canceled = true;
    freeCallbacks();
    if (_subscription != null)
      _subscription.cancel();
    _subscription = null;
  }

  freeCallbacks() {
    if (onUploadProgress != null) {
      onUploadProgress.release();
      onUploadProgress = null;
    }
    if (onDownloadProgress != null) {
      onDownloadProgress.release();
      onDownloadProgress = null;
    }
    if (onComplete != null) {
      onComplete.release();
      onComplete = null;
    }
  }

  getError() => _error;

  @override
  destroy() {
    responseHeader?.release();
    freeCallbacks();
  }
}