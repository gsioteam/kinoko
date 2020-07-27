
import 'package:cache_image/cache_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:kinoko/utils/cached_picture_image.dart';
import 'utils/download_manager.dart';

import 'widgets/home_widget.dart';

class DownloadPage extends HomeWidget {
  @override
  State<StatefulWidget> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  @override
  Widget build(BuildContext context) {
    List<DownloadQueueItem> items = DownloadManager().items;
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        DownloadQueueItem item = items[index];
        DataItem dataItem = DataItem.fromCollectionData(item.data);
        return ListTile(
          leading: Image(image: CacheImage(dataItem.picture)),
          title: Text(dataItem.title),
        );
      }
    );
  }

}