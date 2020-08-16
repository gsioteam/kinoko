import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:glib/core/callback.dart';

import '../core/core.dart';
import '../core/data.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ExtendsRequest {
  void Function(int bytes, int totalBytes) onProgress;

  setOnProgress(void Function(int bytes, int totalBytes) op) {
    onProgress = op;
    return this;
  }
}

class MultipartRequest extends http.MultipartRequest with ExtendsRequest {
  MultipartRequest(String method, Uri uri) : super(method, uri);

  http.ByteStream finalize() {
    final byteStream = super.finalize();
    if (onProgress == null) return byteStream;

    final total = this.contentLength;
    int bytes = 0;

    final t = StreamTransformer.fromHandlers(
      handleData: (List<int> data, EventSink<List<int>> sink) {
        bytes += data.length;
        onProgress(bytes, total);
        sink.add(data);
      },
    );
    final stream = byteStream.transform(t);
    return http.ByteStream(stream);
  }
}

class UrlRequest extends http.Request with ExtendsRequest {
  UrlRequest(String method, Uri uri) : super(method, uri);

  http.ByteStream finalize() {
    final byteStream = super.finalize();
    if (onProgress == null) return byteStream;

    final total = this.contentLength;
    int bytes = 0;

    final t = StreamTransformer.fromHandlers(
      handleData: (List<int> data, EventSink<List<int>> sink) {
        bytes += data.length;
        onProgress(bytes, total);
        sink.add(data);
      },
    );
    final stream = byteStream.transform(t);
    return http.ByteStream(stream);
  }
}

class Request extends Base {
  static reg() {
    Base.reg(Request, "gs::DartRequest", Base)
        ..constructor = ((id) => Request().setID(id));
  }

  Map<String, String> headers = Map();
  Uint8List body;
  http.BaseRequest request;
  int uploadNow;
  int uploadTotal;
  int downloadNow;
  int downloadTotal;

  int _timeout;

  bool _canceled = false, _started = false;
  StreamSubscription<List<int>> _subscription;
  Uint8List responseBody;
  String _error;

  Callback onUploadProgress;
  Callback onDownloadProgress;
  Callback onComplete;

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
  }

  _release() {
    release();
  }

  setup(String method, String url, int type) {
    switch (type) {
      case 0: {
        request = UrlRequest(method, Uri.parse(url)).setOnProgress(uploadProgress);
        break;
      }
      case 1: {
        request = MultipartRequest(method, Uri.parse(url)).setOnProgress(uploadProgress);
        break;
      }
      case 2: {
        request = UrlRequest(method, Uri.parse(url)).setOnProgress(uploadProgress);
        break;
      }
    }
    control();
  }

  Data getResponseBody() {
    return Data.fromByteBuffer(responseBody.buffer).release();
  }

  setHeader(String name, String value) {
    request.headers[name] = value;
  }

  setBody(Pointer<Uint8> ptr, int length) {
    if (request is UrlRequest) {
      var req = request as UrlRequest;
      Uint8List buf = ptr.asTypedList(length);
      req.bodyBytes = Uint8List.fromList(buf);
    }
  }

  setOnUploadProgress(Callback cb) {
    onUploadProgress = cb;
    if (onUploadProgress != null) onUploadProgress.control();
  }

  setOnProgress(Callback cb) {
    onDownloadProgress = cb;
    if (onDownloadProgress != null) onDownloadProgress.control();
  }

  setOnComplete(Callback cb) {
    onComplete = cb;
    if (onComplete != null) onComplete.control();
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
        Stream<FileResponse> stream = DefaultCacheManager().getFileStream(request.url.toString(), headers: request.headers, withProgress: true);
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
        http.StreamedResponse res = await request.send();
        if (_canceled) return;
        print("Start ${request.url} ${_timeout}");
        downloadTotal = res.contentLength;
        downloadNow = 0;
        List<int> receiveBody = List();
        _subscription = res.stream.listen((value) {
          downloadNow += value.length;
          receiveBody.addAll(value);
          if (onDownloadProgress != null) onDownloadProgress.invoke([downloadNow, downloadTotal]);
        });
        await _subscription.asFuture().timeout(Duration(seconds: _timeout == null ? 30 : _timeout), onTimeout: () {
          if (!_canceled) {
            throw new Exception("Timeout");
          }
        });
        responseBody = Uint8List.fromList(receiveBody);
      }

    } catch (e) {
      _error = e.toString();
      print("Error ${_error}");
      if (onComplete != null) onComplete.invoke([]);
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

  getError() {
    return _error;
  }

  @override
  destroy() {
    freeCallbacks();
  }
}