
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:kinoko/pages/main_settings_page.dart';
import 'package:kinoko/utils/file_loader.dart';
import 'package:kinoko/utils/neo_cache_manager.dart';
import 'package:kinoko/widgets/images/one_finger_zoom_gesture_recognizer.dart';
import 'dart:ui' as ui;

abstract class PhotoInformation {
  bool get hasData;

  ImageProvider getImageProvider(NeoCacheManager? cacheManager);
}

class UrlPhotoInformation extends PhotoInformation {
  String? url;
  Map<String, String>? headers;

  UrlPhotoInformation(this.url, [this.headers]);

  @override
  bool get hasData => url != null;

  @override
  ImageProvider<Object> getImageProvider(NeoCacheManager? cacheManager) {
    return NeoImageProvider(
      uri: Uri.parse(url!),
      cacheManager: cacheManager,
      headers: headers,
    );
  }
}

class LoaderPhotoInformation extends PhotoInformation {

  FileLoader? loader;
  String path;

  LoaderPhotoInformation(this.loader, this.path);

  @override
  bool get hasData => loader != null;

  @override
  ImageProvider<Object> getImageProvider(NeoCacheManager? cacheManager) {
    return _FutureMemoryImage(loader!.readFile(path));
  }
}

class _FutureMemoryImage extends ImageProvider<_FutureMemoryImage> {

  const _FutureMemoryImage(this.future, { this.scale = 1.0 });

  final Future<Uint8List> future;

  final double scale;

  @override
  Future<_FutureMemoryImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_FutureMemoryImage>(this);
  }

  @override
  ImageStreamCompleter load(_FutureMemoryImage key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
    );
  }

  Future<ui.Codec> _loadAsync(_FutureMemoryImage key, DecoderCallback decode) async {
    assert(key == this);

    Uint8List bytes = await future;
    return decode(bytes);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is _FutureMemoryImage
        && other.future == future
        && other.scale == scale;
  }

  @override
  int get hashCode => hashValues(future.hashCode, scale);

}

enum BoundType {
  Start,
  End
}

class PagerController {
  Key key = GlobalKey();
  void Function(int)? onPage;
  void Function(BoundType)? onOverBound;
  int _index;
  set index(int v) => _index = v;
  int get index => _index;
  PagerState? state;

  PagerController({
    int index = 0,
    this.onPage,
    this.onOverBound,
  }) : _index = index;


  void dispose() {
    state = null;
  }

  void next() {
    state?.onNext();
  }

  void prev() {
    state?.onPrev();
  }

  void jumpTo(int index) {
    state?.onPage(index, false);
    _index = index;
  }

  void animateTo(int index) {
    state?.onPage(index, true);
    _index = index;
  }

  void _onPage(int page) {
    if (index != page) {
      index = page;
      onPage?.call(page);
    }
  }

}

typedef ImageFetcher = PhotoInformation Function(int index);

abstract class Pager extends StatefulWidget {

  final PagerController controller;
  final NeoCacheManager? cacheManager;
  final int itemCount;
  final ImageFetcher imageUrlProvider;

  Pager({
    Key? key,
    required this.controller,
    this.cacheManager,
    required this.itemCount,
    required this.imageUrlProvider,
  }) : super(key: key);

  @override
  PagerState createState();
}

abstract class PagerState<T extends Pager> extends State<T> {

  @override
  void initState() {
    super.initState();
    widget.controller.state = this;
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.controller.state == this)
      widget.controller.state = null;
  }

  void onNext();
  void onPrev();
  void onPage(int page, bool animate);

  void setPage(int page) => widget.controller._onPage(page);
}