

import 'package:glib/core/array.dart';
import 'package:glib/main/collection_data.dart';
import 'package:kinoko/configs.dart';

class DownloadManager {
  static DownloadManager _instance;

  Array items;

  factory DownloadManager() {
    if (_instance == null) {
      _instance = DownloadManager._();
    }
    return _instance;
  }

  DownloadManager._() {
    items = CollectionData.all(collection_download).control();
  }
}