
import 'dart:collection';
import 'cached_picture_image.dart';
import 'download_manager.dart';

class _PreloadItem {
  bool loaded = false;
  DownloadPictureItem provider;

  _PreloadItem([this.provider]);

  void set(DownloadPictureItem newProvider) {
    if (provider.url != newProvider.url || provider.cacheManager != newProvider.cacheManager) {
      provider = newProvider;
      loaded = false;
    }
  }
}

class PreloadQueue {
  bool canceled = false, loading = false;
  List<_PreloadItem> items = List();
  int _offset = 0;

  void _checkStart() {
    if (canceled || loading)
      return;

    _PreloadItem target;
    for (int i = 0, t = items.length; i < t; ++i) {
      int idx = (_offset + i) % items.length;
      _PreloadItem item = items[idx];
      if (!item.loaded && item.provider != null) {
        target = item;
        break;
      }
    }
    if (target != null) {
      loading = true;
      target.provider.fetchImage((_) {
        target.loaded = true;
        loading = false;
        _checkStart();
      });
    }
  }

  void set(int idx, DownloadPictureItem provider) {
    if (canceled) {
      return;
    }
    if (items.length <= idx) {
      while (items.length < idx) {
        items.add(_PreloadItem());
      }
      items.add(_PreloadItem(provider));
    } else {
      _PreloadItem item = items[idx];
      item.set(provider);
    }
    this._checkStart();
  }

  void stop() {
    canceled = true;
  }

  set offset(int off) => _offset = off;
}