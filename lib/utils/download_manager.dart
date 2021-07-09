

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:glib/core/callback.dart';
import 'package:glib/core/core.dart';
import 'package:glib/core/array.dart';
import 'package:glib/core/gmap.dart';
import 'package:glib/main/collection_data.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/error.dart' as glib;
import 'package:glib/main/project.dart';
import '../configs.dart';
import 'cached_picture_image.dart';
import 'package:glib/utils/bit64.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:math';
import 'book_info.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'data_item_headers.dart';
import 'neo_cache_manager.dart';

enum DownloadState {
  None,
  ListComplete,
  AllComplete,
  Unkown
}

class DownloadPictureItem {
  NeoCacheManager cacheManager;
  String url;
  Map<String, String> headers;
  bool canceled = false;

  DownloadPictureItem(this.url, this.cacheManager, {this.headers});

  void fetchImage(void Function() callback) {
    cacheManager.getSingleFile(Uri.parse(url), headers: headers).then((value) {
      if (!canceled) {
        callback();
      }
    }).catchError((err) {
      print("Download Error : $err");
      if (!canceled) {
        callback();
      }
      return err;
    });
  }

  void cancel() {
    canceled = true;
  }
}

class _DownloadCacheItem {
  String url;
  Map<String, String> headers;

  _DownloadCacheItem(this.url, [this.headers]);
}

class DownloadQueueItem {
  CollectionData data;
  DataItem item;
  void Function(String error) onError;
  NeoCacheManager cacheManager;
  Queue<DownloadPictureItem> queue = Queue();
  bool _picture_downloading = false;
  String cacheKey;
  void Function() onImageQueueClear;
  List<_DownloadCacheItem> urls = List();
  int _total = 0;
  int _total2 = 0;
  int _loaded = 0;
  int _loaded2 = 0;

  bool _downloading = false;
  bool cancel = false;
  Context context;

  static const Duration MaxDuration = Duration(days: 365 * 99999);

  void Function() onProgress;
  void Function() onState;

  bool get downloading => _downloading;

  int get loaded => max(_loaded, _loaded2);
  int get total => max(_total, _total2);

  bool _setup = false;

  BookInfo _info;
  BookInfo get info {
    if (_info == null) {
      if (data.data != null) {
        Map<String, dynamic> map = jsonDecode(data.data);
        _info = BookInfo(
          title: map["title"],
          picture: map["picture"],
          link: map["link"],
          subtitle: map["subtitle"]
        );
      } else {
        _info = BookInfo();
      }
    }
    return _info;
  }

  factory DownloadQueueItem(data) {
    if (data == null) return null;
    DataItem item = DataItem.fromCollectionData(data);
    if (item == null) {
      return null;
    }
    return DownloadQueueItem._(data.control(), item.control());
  }

  DownloadQueueItem._(this.data, this.item) {
    Array subitems = item.getSubItems();
    cacheKey = NeoCacheManager.cacheKey(item);
    cacheManager = NeoCacheManager(cacheKey);
    _total = subitems.length;
    if (state != DownloadState.AllComplete) {
      List<_DownloadCacheItem> urls = [];
      for (int i = 0, t = subitems.length; i < t; ++i) {
        DataItem item = subitems[i];
        urls.add(_DownloadCacheItem(
          item.picture, item.headers
        ));
      }
      _checkImages(urls);
      if (state == DownloadState.ListComplete) {
        this.urls = urls;
      }
    } else {
      _loaded = total;
    }
  }

  void _checkImages(List<_DownloadCacheItem> urls) async {
    int count = 0;
    for (_DownloadCacheItem url in urls) {
      var info = await cacheManager.getFileFromCache(Uri.parse(url.url));
      if ((await info.stat()).size > 0) {
        ++count;
        _loaded = count;
        onProgress?.call();
      }
    }
    if (_loaded == total && state == DownloadState.ListComplete) {
      state = DownloadState.AllComplete;
      data.save();
      onState?.call();
    }
    _setup = true;
  }

  void destroy() {
    r(data);
    data = null;
    r(item);
    item = null;
    r(context);
    context = null;
  }

  DownloadState get state {
    switch (data.flag) {
      case 0: {
        return DownloadState.None;
      }
      case 1: {
        return DownloadState.ListComplete;
      }
      case 2: {
        return DownloadState.AllComplete;
      }
    }
    return DownloadState.Unkown;
  }

  set state(DownloadState s) {
    switch (s) {
      case DownloadState.None: {
        data.flag = 0;
        break;
      }
      case DownloadState.ListComplete: {
        data.flag = 1;
        break;
      }
      case DownloadState.AllComplete: {
        data.flag = 2;
        break;
      }
      default: {}
    }
  }

  DownloadPictureItem currentImage;

  void checkImageQueue() async {
    if (!_downloading) return;
    if (_picture_downloading) return;
    if (queue.length == 0) {
      onImageQueueClear?.call();
      return;
    }

    currentImage = queue.removeFirst();
    _picture_downloading = true;
    currentImage.fetchImage(() {
      currentImage = null;
      _picture_downloading = false;

      _loaded2++;
      onProgress?.call();
      checkImageQueue();
    });
  }

  Future<void> waitForImageQueue() async {
    if (!_picture_downloading && queue.length == 0) return;
    Completer<void> completer = Completer();
    onImageQueueClear = () {
      onImageQueueClear = null;
      completer.complete();
    };
    return completer.future;
  }

  bool contains(String url) {
    for (var item in urls) {
      if (item.url == url) {
        return true;
      }
    }
    return false;
  }

  void addToQueue(String url, {Map<String, String> headers, bool force = false}) {
    if (!contains(url)) {
      urls.add(_DownloadCacheItem(
        url,
        headers
      ));
      _total2 = urls.length;
      onProgress?.call();
      DownloadPictureItem image = DownloadPictureItem(url, cacheManager, headers: headers);
      queue.add(image);
      checkImageQueue();
    } else if (force) {
      DownloadPictureItem image = DownloadPictureItem(url, cacheManager, headers: headers);
      queue.add(image);
      checkImageQueue();
    } else {
      print("not add $url");
    }
  }

  Future<void> reload(Context context) {
    _loaded2 = 0;
    Completer<void> completer = Completer();
    context.onError = Callback.fromFunction((glib.Error error){
      completer.completeError(Exception(error.msg));
    }).release();
    context.onReloadComplete = Callback.fromFunction(() {
      completer.complete();
    }).release();
    context.onDataChanged = Callback.fromFunction((int type, Array data, int idx) {
      for (int i = 0, t = data.length; i < t; ++i) {
        DataItem dataItem = data[i];
        addToQueue(dataItem.picture, headers: dataItem.headers);
      }
    }).release();
    context.enterView();
    context.reload();

    return completer.future;
  }

  Future<bool> main() async {
    Project project = Project.allocate(item.projectKey).release();

    if (!project.isValidated) {
      onError?.call("can not find the item.");
      return false;
    }
    project.control();

    context = project.createCollectionContext(CHAPTER_INDEX, item).control();

    try {
      if (state == DownloadState.None) {
        urls.clear();
        await reload(context);
        state = DownloadState.ListComplete;
        data.save();
        onState?.call();
      } else {
        _loaded = max(_loaded, _loaded2);
        _loaded2 = 0;
        var tmp = List.from(urls.map((e) => e.url));
        urls.clear();
        queue.clear();
        tmp.forEach((url) {
          addToQueue(url);
        });
      }
      if (state == DownloadState.ListComplete) {
        await waitForImageQueue();
        state = DownloadState.AllComplete;
        data.save();
        onState?.call();
      }
    } catch (e) {
      if (_downloading)
        onError?.call(e.toString());
    }

    if (context != null) {
      context.release();
      context = null;
    }
    project.release();
    return true;
  }

  void start() async {
    if (_downloading) {
      print("It is downloading.");
      return;
    }
    if (state != DownloadState.AllComplete) {
      _downloading = true;
      await main();
      _downloading = false;
    } else {
      print("Already complete!");
    }
  }

  void stop() {
    if (context != null) {
      context.release();
      context = null;
    }
    if (currentImage != null) {
      currentImage.cancel();
      currentImage = null;
      _picture_downloading = false;
    }
    _downloading = false;
  }
}

class DownloadManager {
  static DownloadManager _instance;
  Queue<DownloadQueueItem> queue = Queue();

  Array data;
  List<DownloadQueueItem> items = List();

  factory DownloadManager() {
    if (_instance == null) {
      _instance = DownloadManager._();
    }
    return _instance;
  }

  static void reloadAll() {
    Array data = CollectionData.all(collection_download);
    for (CollectionData item in data) {
      if (item.flag == 2) {
        item.flag = 1;
        item.save();
      }
    }
    _instance = null;
  }

  DownloadManager._() {
    data = CollectionData.all(collection_download).control();
    for (int  i = 0, t = data.length; i < t; ++i) {
      CollectionData d = data[i];
      DownloadQueueItem queueItem = DownloadQueueItem(d);
      if (queueItem != null)
        items.add(queueItem);
    }
  }

  DownloadQueueItem add(DataItem item, BookInfo bookInfo) {
    if (!item.isInCollection(collection_download)) {
      CollectionData data = item.saveToCollection(collection_download, {
        "title": bookInfo.title,
        "picture": bookInfo.picture,
        "link": bookInfo.link,
        "subtitle": bookInfo.subtitle
      });
      DownloadQueueItem queueItem = DownloadQueueItem(data);
      if (queueItem != null)
        items.add(queueItem);
      return queueItem;
    }
    return null;
  }

  void remove(int idx) {
    if (idx < items.length) {
      DownloadQueueItem item = items[idx];
      item.stop();
      item.data.remove();
      item.destroy();
      items.removeAt(idx);
    }
  }

  void removeItem(DownloadQueueItem item) {
    item.stop();
    item.data.remove();
    item.destroy();
    items.remove(item);
  }

  DownloadQueueItem find(DataItem item) {
    for (int i = 0, t = items.length; i < t; ++i) {
      String link = items[i].item.link;
      if (item.link == link) {
        return items[i];
      }
    }
    return null;
  }
}