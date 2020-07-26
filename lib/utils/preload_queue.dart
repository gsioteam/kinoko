
import 'dart:collection';
import 'cached_picture_image.dart';

class PreloadQueue {
  bool stoped = false, loading = false;
  Queue<CachedPictureImage> queue = Queue();


  void _checkStart() {
    if (stoped || loading)
      return;
    if (queue.length > 0) {
      CachedPictureImage cache = queue.removeFirst();
      loading = true;
      print("Start " + cache.url);
      cache.fetchImage().then((value) {
        loading = false;
        print("Complete " + cache.url);
        _checkStart();
      });
    }
  }

  void add(CachedPictureImage provider) {
    if (stoped) {
      print("PreloadQueue is stoped");
      return;
    }
    queue.add(provider);
    this._checkStart();
  }

  void stop() {
    stoped = true;
  }
}