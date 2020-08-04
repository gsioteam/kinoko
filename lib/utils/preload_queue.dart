
import 'dart:collection';
import 'cached_picture_image.dart';
import 'download_manager.dart';

class PreloadQueue {
  bool stoped = false, loading = false;
  Queue<DownloadPictureItem> queue = Queue();


  void _checkStart() {
    if (stoped || loading)
      return;
    if (queue.length > 0) {
      DownloadPictureItem cache = queue.removeFirst();
      loading = true;
      cache.fetchImage().then((value) {
        loading = false;
        _checkStart();
      }).catchError((err) {
        loading = false;
        _checkStart();
      });
    }
  }

  void add(DownloadPictureItem provider) {
    if (stoped) {
      return;
    }
    queue.add(provider);
    this._checkStart();
  }

  void stop() {
    stoped = true;
  }
}