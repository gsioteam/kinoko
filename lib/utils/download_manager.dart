

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/collection_data.dart';
import 'package:glib/main/data_item.dart';
import 'package:kinoko/utils/key_value_storage.dart';
import 'package:kinoko/utils/plugin/manga_loader.dart';
import 'package:kinoko/utils/plugins_manager.dart';
import '../configs.dart';
import 'book_info.dart';
import 'neo_cache_manager.dart';
import 'plugin/plugin.dart';

enum DownloadState {
  Paused,
  Downloading,
  Complete,
}

class DownloaderException with Exception {
  final String label;
  final String reason;

  const DownloaderException([this.label = "", this.reason = ""]);

  @override
  String toString() {
    return "[$label] $reason";
  }
}

class _DownloaderValue {
  int loaded;
  int total;

  _DownloaderValue({
    required this.loaded,
    required this.total
  });

  _DownloaderValue copyWith({
    int? loaded,
    int? total,
  }) {
    return _DownloaderValue(
      loaded: loaded ?? this.loaded,
      total: total ?? this.total
    );
  }
}

class _PictureDownloader extends ValueNotifier<_DownloaderValue> {
  DownloadQueueItem item;
  late Processor processor;
  bool canceled = false;

  _PictureDownloader(this.item, Plugin plugin) : super(_DownloaderValue(
    loaded: item.loaded,
    total: item.total,
  )) {
    processor = Processor(plugin: plugin, data: item.info.data);
  }

  Future<bool> start() async {
    if (!processor.isComplete) {
      try {
        await processor.load();
      } catch (e) {
        throw DownloaderException("fail_to_load_list", e.toString());
      }
    }
    if (!processor.isComplete) {
      throw DownloaderException("fail_to_load_list", "unkown");
    }

    // check exist item
    int loaded = 0;
    List<Picture> needToLoad = [];
    for (var picture in processor.value) {
      String? url = picture.url;
      if (url != null) {
        if (await item.cacheManager.exist(Uri.parse(url))) {
          loaded++;
        } else {
          needToLoad.add(picture);
        }
      } else {
        throw DownloaderException("fail_to_load_list", "url_null_error");
      }
    }

    if (canceled) return false;
    value = value.copyWith(
      loaded: loaded,
      total: processor.value.length,
    );

    for (var pic in needToLoad) {
      int count = 0;
      while (true) {
        try {
          await _loadImage(pic);
          if (canceled) return false;
          loaded++;
          value = value.copyWith(
            loaded: loaded,
          );
          break;
        } catch (e) {
          if (count >= 3) {
            throw DownloaderException("download_failed", e.toString());
          }
        }
      }
    }
    return true;
  }

  Future<void> _loadImage(Picture picture) async {
    var imageProvider = NeoImageProvider(
      uri: Uri.parse(picture.url!),
      headers: picture.headersMap,
      cacheManager: item.cacheManager,
    );

    Completer<void> completer = Completer();
    var stream = imageProvider.resolve(ImageConfiguration.empty);
    ImageStreamListener listener = ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        completer.complete();
      },
      onError: (e, stack) {
        completer.completeError(e, stack);
      }
    );
    stream.addListener(listener);
    try {
      await completer.future;
      stream.removeListener(listener);
    } catch(e) {
      imageProvider.evict();
      stream.removeListener(listener);
      rethrow;
    }
  }

  void stop() {
    canceled = true;
  }

  @override
  void dispose() {
    super.dispose();
    processor.dispose();
  }
}

class DownloadPictureItem {
  NeoCacheManager cacheManager;
  String url;
  Map<String, String>? headers;
  bool canceled = false;

  DownloadPictureItem(this.url, this.cacheManager, {this.headers});

  void fetchImage(void Function(bool success) callback) {
    cacheManager.getSingleFile(Uri.parse(url), headers: headers).then((value) {
      if (!canceled) {
        callback(true);
      }
    }).catchError((err) {
      print("Download Error : $err");
      if (!canceled) {
        callback(false);
      }
    });
  }

  void cancel() {
    canceled = true;
  }

  void reset() {
    cacheManager.reset(Uri.parse(url));
  }
}

class DownloadItemValue {
  int loaded;
  int total;
  DownloaderException error;
  DownloadState state;

  DownloadItemValue({
    this.loaded = 0,
    this.total = 0,
    this.error = const DownloaderException("", ""),
    this.state = DownloadState.Paused,
  });

  DownloadItemValue copyWith({
    int? loaded,
    int? total,
    DownloaderException? error,
    DownloadState? state,
  }) {
    return DownloadItemValue(
      loaded: loaded ?? this.loaded,
      total: total ?? this.total,
      error: error ?? this.error,
      state: state ?? this.state,
    );
  }

  bool get hasError => error.label.isNotEmpty;
}

class DownloadQueueItem extends ValueNotifier<DownloadItemValue> {
  DownloadManager manager;
  late NeoCacheManager cacheManager;
  late String cacheKey;
  void Function()? onImageQueueClear;

  static const Duration MaxDuration = Duration(days: 365 * 99999);

  int get loaded => value.loaded;
  int get total => value.total;

  final BookInfo info;
  final String pluginID;

  _PictureDownloader? _downloader;

  DownloadQueueItem.fromData(this.manager, Map data) :
        info = BookInfo.fromData(data["info"]),
        pluginID = data["pluginID"],
        super(DownloadItemValue(
        loaded: data["loaded"] ?? 0,
        state: data["complete"] == true ? DownloadState.Complete : DownloadState.Paused,
      )) {
    _setup();
  }

  DownloadQueueItem._(this.manager, this.info, this.pluginID) : super(DownloadItemValue()) {
    _setup();
  }

  void _setup() {
    Plugin? plugin = PluginsManager.instance.findPlugin(pluginID);

    if (plugin != null) {
      var processor = Processor(
          plugin: plugin,
          data: info.data
      );
      cacheKey = NeoCacheManager.cacheKey(processor);
      cacheManager = NeoCacheManager(cacheKey);

      value = value.copyWith(
        total: processor.value.length,
      );

      processor.dispose();
    } else {
      value = value.copyWith(
        error: DownloaderException("no_project_found", ""),
      );
      cacheKey = NeoCacheManager.cacheOldKey(pluginID, info);
      cacheManager = NeoCacheManager(cacheKey);
    }
  }

  DownloadState get state => value.state;

  void start() async {
    if (state == DownloadState.Paused) {
      value = value.copyWith(
        error: DownloaderException(),
      );
      Plugin? plugin = PluginsManager.instance.findPlugin(pluginID);
      if (plugin == null) {
        value = value.copyWith(
          error: DownloaderException("no_project_found"),
        );
        return;
      }
      var downloader = _PictureDownloader(this, plugin);
      _downloader = downloader;
      downloader.addListener(() {
        value = value.copyWith(
          loaded: downloader.value.loaded,
          total: downloader.value.total,
        );
        manager._itemUpdate(this);
      });
      try {
        value = value.copyWith(
          state: DownloadState.Downloading,
        );
        bool complete = await downloader.start();
        value = value.copyWith(
          state: complete ? DownloadState.Complete : DownloadState.Paused,
        );
        manager._itemUpdate(this);
      } catch (e) {
        DownloaderException err;
        if (e is DownloaderException) {
          err = e;
        } else {
          err = DownloaderException("unkown", e.toString());
        }
        value = value.copyWith(
          error: err,
          state: DownloadState.Paused,
        );
      }
      downloader.dispose();
      _downloader = null;
    }
  }

  void stop() {
    if (state == DownloadState.Downloading) {
      _downloader?.stop();
      _downloader = null;
      value = value.copyWith(
        state: DownloadState.Paused,
      );
    }
  }

  toData() {
    return {
      "info": info.toData(),
      "pluginID": pluginID,
      "loaded": loaded,
      "complete": state == DownloadState.Complete,
    };
  }
}

class DownloadManager {
  static DownloadManager? _instance;

  factory DownloadManager() {
    if (_instance == null) {
      _instance = DownloadManager._();
    }
    return _instance!;
  }

  late KeyValueStorage<List<DownloadQueueItem>> items;

  static void reloadAll() {
    Array? data = CollectionData.all(collection_download);
    if (data != null) {
      for (CollectionData item in data) {
        if (item.flag == 2) {
          item.flag = 1;
          item.save();
        }
      }
    }
    _instance = null;
  }

  DownloadManager._() {
    items = KeyValueStorage(
      key: "download_items",
      decoder: (text) {
        if (text.isNotEmpty) {
          List list = jsonDecode(text);
          List<DownloadQueueItem> ret = [];
          for (var data in list) {
            try {
              ret.add(DownloadQueueItem.fromData(this, data));
            } catch (e) {
            }
          }
          return ret;
        } else {
          return [];
        }
      },
      encoder: (list) => jsonEncode(list.map((e) => e.toData()).toList()),
    );

    Set<String> index = {};
    for (var item in items.data) {
      index.add(item.info.key);
    }

    var data = CollectionData.all(collection_download);
    if (data != null) {
      for (int  i = 0, t = data.length; i < t; ++i) {
        CollectionData collectionData = data[i];
        DataItem? item = DataItem.fromCollectionData(collectionData);
        if (item != null) {
          if (!index.contains(item.link)) {
            Map<String, dynamic> map = jsonDecode(collectionData.data);
            var info = BookInfo(
              key: item.link,
              title: map["title"],
              picture: map["picture"],
              link: map["link"],
              subtitle: map["subtitle"],
              data: {
                "title": item.title,
                "subtitle": item.subtitle,
                "link": item.link,
              },
            );
            items.data.add(DownloadQueueItem._(this, info, item.projectKey));
          }
        }
      }
    }
  }

  DownloadQueueItem? add(BookInfo bookInfo, Plugin plugin) {
    for (var item in items.data) {
      if (item.info.key == bookInfo.key) {
        return null;
      }
    }
    DownloadQueueItem item = DownloadQueueItem._(this, bookInfo, plugin.id);
    items.data.add(item);
    items.update();
    return item;
  }

  void remove(int idx) {
    if (idx < items.data.length) {
      DownloadQueueItem item = items.data[idx];
      item.stop();
      item.dispose();
      items.data.removeAt(idx);
      items.update();
    }
  }

  void removeKey(String key) {
    for (var item in items.data) {
      if (item.info.key == key) {
        item.stop();
        item.dispose();
        items.data.remove(item);
        items.update();
        return;
      }
    }
  }

  bool exist(String key) {
    for (var item in items.data) {
      if (item.info.key == key) return true;
    }
    return false;
  }

  void _itemUpdate(DownloadQueueItem item) {
    if (items.data.contains(item)) {
      items.update();
    }
  }
}