
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

  String url;
  Map headers;
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

  Future<Codec> _fetchImage() async {
    Stream<FileResponse> stream = cacheManager.getFileStream(
      url,
      headers: headers
    );
    FileInfo fileInfo;
    await for (FileResponse res in stream) {
      if (res is FileInfo) {
        fileInfo = res;
      }
    }
    if (fileInfo != null) {
      return PaintingBinding.instance.instantiateImageCodec(await fileInfo.file.readAsBytes());
    }
    return null;
  }

  @override
  ImageStreamCompleter load(CachedPictureImage key, decode) {
    return MultiFrameImageStreamCompleter(
      codec: _fetchImage(),
      scale: this.scale,
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