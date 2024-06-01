
import 'dart:async';
import 'dart:io' as io;
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file/src/interface/file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/models.dart';
import 'package:kinoko/utils/book_info.dart';
import 'package:kinoko/utils/plugin/manga_loader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file/local.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:file/file.dart';
import 'package:dio/dio.dart';
import 'package:dio/adapter.dart';


class SizeResult {
  int cached = 0;
  int other = 0;
}

// class ProviderKey {
//   ImageConfiguration configuration;
//   NeoImageProvider provider;
//
//   ProviderKey(this.provider, this.configuration);
//
//   @override
//   bool operator ==(Object other) {
//     if (other is ProviderKey) {
//       return configuration == other.configuration && provider == other.provider;
//     }
//     return false;
//   }
//
//   @override
//   int get hashCode => 0x88fa000 | provider.hashCode | configuration.hashCode;
// }

class NeoError extends Error {
  final String msg;

  NeoError(this.msg);

  @override
  String toString() => msg;
}

const String dir_key = "neo_directory";

class NeoCacheManager {

  static Future<Directory>? _root;
  late Future<Directory> _directory;

  static Map<String, NeoCacheManager> _managers = {};

  final String key;

  NeoCacheManager._(String key) : key = key {
    _directory = _getDirectory(key);
  }

  static NeoCacheManager? _defaultManager;
  static NeoCacheManager get defaultManager {
    if (_defaultManager == null) {
      _defaultManager = NeoCacheManager._("default");
    }
    return _defaultManager!;
  }

  factory NeoCacheManager(String key) {
    NeoCacheManager? manager = _managers[key];
    if (manager == null)
      manager = _managers[key] = NeoCacheManager._(key);
    return manager;
  }

  static Future<Directory> get root {
    if (_root == null) {
      _root = getRoot();
    }
    return _root!;
  }
  static Future<Directory> getRoot() async {
    String path = KeyValue.get(dir_key);
    if (path.isNotEmpty) {
      Directory root = LocalFileSystem().directory(path);
      if (await root.exists())
        return root;
    }
    try {
      var temp = await getExternalStorageDirectory();
      if (temp != null) {
        String path = p.join(temp.path, "pic");
        Directory root = LocalFileSystem().directory(path);
        if (!await root.exists()) {
          await root.create(recursive: true);
        }
        KeyValue.set(dir_key, path);
        return root;
      }
    } catch (e) {

    }

    try {
      var temp = await getApplicationSupportDirectory();
      String path = p.join(temp.path, "pic");
      Directory root = LocalFileSystem().directory(path);
      if (!await root.exists()) {
        await root.create(recursive: true);
      }
      KeyValue.set(dir_key, path);
      return root;
    } catch (e) {

    }

    try {
      var temp = await getTemporaryDirectory();
      String path = p.join(temp.path, "pic");
      Directory root = LocalFileSystem().directory(path);
      if (!await root.exists()) {
        await root.create(recursive: true);
      }
      KeyValue.set(dir_key, path);
      return root;
    } catch (e) {

    }
    throw Exception("Can not find storage path.");
  }

  Future<Directory> _getDirectory(String key) async {
    return LocalFileSystem().directory(p.join((await root).path, key));
  }

  Future<File> getFileFromCache(Uri uri) async {
    return (await _directory).childFile(NeoImageProvider.getFilename(uri));
  }

  Future<File> getSingleFile(Uri uri, {Map<String, String>? headers}) async {
    var file = (await _directory).childFile(NeoImageProvider.getFilename(uri));
    if (!await file.exists()) {
      var provider = NeoImageProvider(
        cacheManager: this,
        uri: uri,
        headers: headers
      );
      var stream = provider.resolve(ImageConfiguration.empty);
      Completer<void> completer = Completer();
      ImageStreamListener? listener;
      listener = ImageStreamListener((image, info) {
        stream.removeListener(listener!);
        completer.complete();
      }, onError: (e, stack) {
        stream.removeListener(listener!);
        completer.completeError(e, stack);
      });
      stream.addListener(listener);
      await completer.future;
    }
    return file;
  }

  Future<bool> exist(Uri uri) async {
    var file = (await _directory).childFile(NeoImageProvider.getFilename(uri));
    return await file.exists();
  }

  Future<void> reset(Uri uri) async {
    var provider = NeoImageProvider(
        cacheManager: this,
        uri: uri,
    );
    provider.evict();
  }

  static String _generateMd5(String input) => md5.convert(utf8.encode(input)).toString();
  static String cacheKey(Processor item) => "${item.plugin.id}/${_generateMd5(item.data["link"])}";
  static String cacheOldKey(String pluginID, BookInfo info) => "$pluginID/${_generateMd5((info.data as Map)["link"])}";

  static Future<SizeResult> calculateCacheSize({Set<String>? cached}) async {
    if (cached == null) cached = Set();
    String path = (await root).path;
    var dir = io.Directory(path);
    SizeResult result = SizeResult();
    await for (var entry in dir.list(recursive: true, followLinks: false)) {
      if (entry is io.File) {
        var segs = entry.path.replaceFirst("$path/", "").split('/');
        if (segs.length > 2) {
          var key = "${segs[0]}/${segs[1]}";
          if (cached.contains(key)) {
            result.cached += (await entry.stat()).size;
          } else {
            result.other += (await entry.stat()).size;
          }
        }  else {
          result.other += (await entry.stat()).size;
        }
      }
    }
    return result;
  }

  static Future<void> clearCache({Set<String>? without}) async {
    if (without == null) without = Set();
    String path = (await root).path;
    var dir = io.Directory(path);
    await for (var firstEntry in dir.list(followLinks: false)) {
      if (firstEntry is io.Directory) {
        String firstName = p.basename(firstEntry.path);
        await for (var secondEntry in firstEntry.list(followLinks: false)) {
          String secondName = p.basename(secondEntry.path);
          String key = "$firstName/$secondName";
          if (!without.contains(key)) {
            await secondEntry.delete(recursive: true);
          }
        }
        try {
          await firstEntry.delete();
        } catch (e) {
          // not empty
        }
      } else {
        await firstEntry.delete();
      }
    }
  }

  // Map<ProviderKey, NeoImageProvider> _providers = {};
}

class NeoImageProvider extends ImageProvider<NeoImageProvider> {

  final Uri uri;
  final Map<String, String>? headers;
  late NeoCacheManager cacheManager;
  late String filename;
  final Duration timeout;

  NeoImageProvider({
    NeoCacheManager? cacheManager,
    required this.uri,
    this.headers,
    this.timeout = const Duration(seconds: 20),
  }) {
    if (cacheManager == null) {
      this.cacheManager = NeoCacheManager.defaultManager;
    } else {
      this.cacheManager = cacheManager;
    }
    filename = getFilename(uri);
  }

  @override
  ImageStreamCompleter load(NeoImageProvider key, decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: 1.0,
      informationCollector: () sync* {
        yield DiagnosticsProperty<ImageProvider>(
          'Image provider: $this \n Image key: $key',
          this,
          style: DiagnosticsTreeStyle.errorProperty,
        );
      },
    );
  }

  @override
  Future<NeoImageProvider> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  Stream<ui.Codec> _loadAsync(
      NeoImageProvider key,
      StreamController<ImageChunkEvent> chunkEvents,
      ImageDecoderCallback decode,
      ) async* {
    var dir = await cacheManager._directory;
    File file = dir.childFile(filename);

    if (await file.exists()) {
      var bytes = await file.readAsBytes();
      var decoded = await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
      yield decoded;
    } else {
      Dio dio = Dio(
        BaseOptions(
          method: "GET",
          responseType: ResponseType.stream,
          connectTimeout: 5000,
          receiveTimeout: 15000,
          sendTimeout: 5000,
        ),
      );
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
        client.badCertificateCallback =
            (io.X509Certificate cert, String host, int port) => true;
        return client;
      };
      Response<ResponseBody> response = await dio.requestUri(
        key.uri,
        options: Options(
            headers: key.headers
        ),
      );
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        io.BytesBuilder builder = io.BytesBuilder();
        await for (var chunk in response.data!.stream) {
          builder.add(chunk);
          chunkEvents.add(ImageChunkEvent(
              cumulativeBytesLoaded: builder.length,
              expectedTotalBytes: int.tryParse(response.headers.value(Headers.contentLengthHeader) ?? "0") ?? 0
          ));
        }
        var bytes = builder.toBytes();
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        await file.writeAsBytes(bytes);
        var decoded = await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
        yield decoded;
      } else {
        throw NeoError("Status code ${response.statusCode}");
      }
    }
  }

  static String getFilename(Uri uri) {
    String ext = p.extension(uri.path);
    String name = hex.encode(md5.convert(utf8.encode(uri.toString())).bytes);
    return "$name$ext";
  }

  @override
  bool operator ==(Object other) {
    if (other is NeoImageProvider) {
      return uri == other.uri && cacheManager == other.cacheManager;
    }
    return super == other;
  }

  @override
  int get hashCode => 0x928300 | uri.hashCode | cacheManager.hashCode;
}
