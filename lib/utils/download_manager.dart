

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:glib/core/callback.dart';
import 'package:glib/core/core.dart';
import 'package:glib/core/array.dart';
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

enum DownloadState {
  None,
  ListComplete,
  AllComplete,
  Unkown
}

class DownloadQueueItem {
  CollectionData data;
  DataItem item;
  void Function(String error) onError;
  Queue<CachedPictureImage> queue = Queue();
  bool _picture_downloading = false;
  String cacheKey;
  void Function() onImageQueueClear;
  List<String> urls = List();
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
    cacheKey = item.projectKey + "/" + Bit64.encodeString(item.link);
    _total = subitems.length;
    if (state != DownloadState.AllComplete) {
      List<String> urls = [];
      for (int i = 0, t = subitems.length; i < t; ++i) {
        DataItem item = subitems[i];
        urls.add(item.picture);
      }
      _checkImages(urls);
      if (state == DownloadState.ListComplete) {
        this.urls = urls;
      }
    } else {
      _loaded = total;
    }
  }

  void _checkImages(List<String> urls) async {
    int count = 0;
    PictureCacheManager cacheManager = PictureCacheManager(
      cacheKey,
      maxAgeCacheObject: MaxDuration
    );
    for (String url in urls) {
      FileInfo info = await cacheManager.getFileFromCache(url);
      if (info != null) {
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

  void set state(DownloadState s) {
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

  void checkImageQueue() async {
    if (!_downloading) return;
    if (_picture_downloading) return;
    if (queue.length == 0) {
      onImageQueueClear?.call();
      return;
    }

    CachedPictureImage image = queue.removeFirst();
    _picture_downloading = true;
    await image.fetchImage();
    _picture_downloading = false;
    _loaded2++;
    onProgress?.call();
    checkImageQueue();
  }

  Future<void> waitForImageQueue() async {
    if (!downloading && queue.length == 0) return;
    Completer<void> completer = Completer();
    onImageQueueClear = () {
      onImageQueueClear = null;
      completer.complete();
    };
    return completer.future;
  }

  void addToQueue(url) {
    if (!urls.contains(url)) {
      urls.add(url);
      _total2 = urls.length;
      onProgress?.call();
      CachedPictureImage image = CachedPictureImage(
          url,
          key: cacheKey,
          maxAgeCacheObject: Duration(days: 365 * 99999)
      );
      queue.add(image);
      checkImageQueue();
    }
  }

  Future<void> reload(Context context) {
    _loaded2 = 0;
    Completer<void> completer = Completer();
    context.on_error = Callback.fromFunction((glib.Error error){
      completer.completeError(Exception(error.msg));
    }).release();
    context.on_reload_complete = Callback.fromFunction(() {
      completer.complete();
    }).release();
    context.on_data_changed = Callback.fromFunction((int type, Array data, int idx) {
      for (int i = 0, t = data.length; i < t; ++i) {
        addToQueue(data[i].picture);
      }
    }).release();
    context.enterView();
    context.reload();

    return completer.future;
  }

  Future<bool> main() async {
    Project project = Project.allocate(item.projectKey);

    if (!project.isValidated) {
      onError?.call("can not find the item.");
      return false;
    }
    project.control();

    context = project.createChapterContext(item).control();

    try {
      if (state == DownloadState.None) {
        urls.clear();
        await reload(context);
        state = DownloadState.ListComplete;
        data.save();
        onState?.call();
      } else {
        _loaded2 = 0;
        urls.forEach((url) {
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