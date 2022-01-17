
import 'package:flutter/cupertino.dart';
import 'package:kinoko/utils/file_loader.dart';
import 'package:kinoko/utils/neo_cache_manager.dart';
import 'package:kinoko/widgets/pager/pager.dart';

import 'download_manager.dart';
import 'plugin/manga_loader.dart';
import 'plugin/plugin.dart';
import 'preload_queue.dart';

abstract class PictureController extends ChangeNotifier {

  final ValueNotifier<bool> loading = ValueNotifier(false);

  bool get hasNext;
  bool get hasPrev;

  void goNext();
  void goPrev();

  int get length;

  PhotoInformation getPicture(int index);

  NeoCacheManager? get cacheManager;

  void onPage(int page);

  String get title;

  @override
  void dispose() {
    super.dispose();
    loading.dispose();
  }
}

abstract class PictureData {
  String get key;

  PictureController createController();

}

class RemotePictureController extends PictureController {

  late Processor current;
  Processor? next;
  Processor? prev;

  RemotePictureData data;
  int currentIndex;

  NeoCacheManager? cacheManager;
  late PreloadQueue preloadQueue;

  RemotePictureController({
    required this.data,
  }) : currentIndex = data.initializeIndex {
    current = Processor(
        plugin: data.plugin,
        data: data.list[currentIndex]
    );
    current.addListener(_update);
    current.loading.addListener(_onLoadingUpdate);
    _sideInit();

    if (data.bookKey != null) {
      data.plugin.storage.set("book:last:${data.bookKey}", current.key);
    }
  }

  void _sideInit() {
    preloadQueue = PreloadQueue();
    cacheManager = NeoCacheManager(NeoCacheManager.cacheKey(current));
    if (next == null && hasNext) {
      next = Processor(
        plugin: data.plugin,
        data: data.list[currentIndex + 1],
      );
    }
    if (prev == null && hasPrev) {
      next = Processor(
        plugin: data.plugin,
        data: data.list[currentIndex - 1],
      );
    }
    _loadAll();
  }

  void _loadAll() async {
    await current.load();
    await next?.load();
    await prev?.load();
  }

  @override
  void goNext() {
    if (!hasNext) return;
    preloadQueue.stop();
    prev?.dispose();
    prev = current;
    current.removeListener(_update);
    current.loading.removeListener(_onLoadingUpdate);
    current = next!;
    loading.value = current.loading.value;
    current.addListener(_update);
    current.loading.addListener(_onLoadingUpdate);
    next = null;
    currentIndex += 1;
    _sideInit();
    if (data.bookKey != null) {
      data.plugin.storage.set("book:last:${data.bookKey}", current.key);
    }
  }

  @override
  void goPrev() {
    if (!hasPrev) return;
    preloadQueue.stop();
    next?.dispose();
    next = current;
    current.removeListener(_update);
    current.loading.removeListener(_onLoadingUpdate);
    prev = current;
    loading.value = current.loading.value;
    current.addListener(_update);
    current.loading.addListener(_onLoadingUpdate);
    prev = null;
    currentIndex -= 1;
    _sideInit();
    if (data.bookKey != null) {
      data.plugin.storage.set("book:last:${data.bookKey}", current.key);
    }
  }

  @override
  bool get hasNext => currentIndex < data.list.length - 1;

  @override
  bool get hasPrev => currentIndex > 0;

  @override
  int get length => current.value.length;

  @override
  void dispose() {
    super.dispose();
    current.dispose();
    prev?.dispose();
    next?.dispose();
  }

  @override
  PhotoInformation getPicture(int index) {
    var item = current.value[index];
    return UrlPhotoInformation(item.url, item.headersMap);
  }

  void _update() {
    for (int i = 0 ,t = length; i < t; ++i) {
      var picture = getPicture(i);
      if (picture is UrlPhotoInformation) {
        if (picture.url != null)
          preloadQueue.set(i, DownloadPictureItem(
              picture.url!,
              cacheManager!,
              headers: picture.headers
          ));
      }
    }
    notifyListeners();
  }

  void _onLoadingUpdate() {
    loading.value = current.loading.value;
  }

  @override
  void onPage(int page) {
    preloadQueue.offset = page;
  }

  @override
  String get title => current.data["title"] ?? "";
}

class RemotePictureData extends PictureData {
  final Plugin plugin;
  final List list;
  final int initializeIndex;
  final String? bookKey;

  RemotePictureData({
    required this.plugin,
    required this.list,
    required this.initializeIndex,
    this.bookKey,
  });

  @override
  String get key => plugin.id;

  PictureController createController() => RemotePictureController(data: this);
}

class LocalPictureController extends PictureController {

  final LocalPictureData data;
  FileLoader? loader;
  List<String> pictures = [];

  LocalPictureController(this.data) {
    _setup();
    FileLoader.create(data.path).then((value) {
      loader = value;
    });
  }
  
  void _setup() async {
    loader = await FileLoader.create(data.path);
    if (loader != null) {
      pictures.clear();
      await for (var path in loader!.getPictures()) {
        pictures.add(path);
      }
      notifyListeners();
    }
  }

  @override
  NeoCacheManager? get cacheManager => null;

  @override
  PhotoInformation getPicture(int index) => LoaderPhotoInformation(loader, pictures[index]);

  @override
  void goNext() {
  }

  @override
  void goPrev() {
  }

  @override
  bool get hasNext => false;

  @override
  bool get hasPrev => false;

  @override
  int get length => pictures.length;

  @override
  void onPage(int page) {
  }

  @override
  String get title => data.title;

}

class LocalPictureData extends PictureData {

  final String path;
  final String title;

  LocalPictureData({
    required this.path,
    required this.title,
  });

  @override
  String get key => path;

  @override
  PictureController createController() => LocalPictureController(this);

}