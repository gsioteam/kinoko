
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PictureCacheManager extends BaseCacheManager {
  String key;

  PictureCacheManager(this.key, {
    Duration maxAgeCacheObject,
  }) : super(
      key,
      maxAgeCacheObject: maxAgeCacheObject
  );

  @override
  Future<String> getFilePath() async {
    var directory = await getTemporaryDirectory();
    return p.join(directory.path, "pic", key);
  }

}

class CachedPictureImage extends ImageProvider<CachedPictureImage> {

  static Map<String, Completer<Codec>> processing = Map();
  String url;
  Map<String, String> headers;
  double scale;
  PictureCacheManager cacheManager;

  CachedPictureImage(this.url, {
    String key = "others",
    Duration maxAgeCacheObject,
    this.headers,
    this.scale = 1.0,
  }) {
    cacheManager = PictureCacheManager(key, maxAgeCacheObject: maxAgeCacheObject);
  }

  Future<Codec> fetchImage() async {
    if (processing.containsKey(url)) {
      return processing[url].future;
    } else {
      Completer<Codec> completer = Completer();
      processing[url] = completer;
      File file = await cacheManager.getSingleFile(
          url,
          headers: headers
      );
      var res;
      if (file != null) {
        res = await PaintingBinding.instance.instantiateImageCodec(await file.readAsBytes());
      }
      processing.remove(url);
      completer.complete(res);
      return res;
    }
  }

  @override
  ImageStreamCompleter load(CachedPictureImage key, decode) {
    return MultiFrameImageStreamCompleter(
      codec: key.fetchImage(),
      scale: key.scale,
      informationCollector: () sync* {
        yield DiagnosticsProperty<ImageProvider>(
        'Image provider: $this \n Image key: $key', this,
        style: DiagnosticsTreeStyle.errorProperty);
      }
    );
  }

  @override
  Future<CachedPictureImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<CachedPictureImage>(this);
  }

}