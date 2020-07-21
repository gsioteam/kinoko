
import 'package:cache_image/cache_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class PictureViewer extends StatefulWidget {
  Context context;

  PictureViewer(this.context);

  @override
  State<StatefulWidget> createState() {
    return _PictureViewerState();
  }
}

class _PictureViewerState extends State<PictureViewer> {

  Array data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: PhotoViewGallery.builder(
          itemCount: data.length,
          builder: (BuildContext context, int index) {
            DataItem item = data[index];
            return PhotoViewGalleryPageOptions(
              imageProvider: CacheImage(item.picture),
              initialScale: PhotoViewComputedScale.contained,
//              heroAttributes: HeroAttributes(tag: galleryItems[index].id),
            );
          },

          loadingBuilder: (context, event) => Center(
            child: Container(
              width: 20.0,
              height: 20.0,
              child: CircularProgressIndicator(
                value: event == null
                    ? 0
                    : event.cumulativeBytesLoaded / event.expectedTotalBytes,
              ),
            ),
          ),

        ),
      ),
    );

    initState() {
      widget.context.enterView();
      data = widget.context.data.control();
      super.initState();
    }

    dispose() {
      widget.context.exitView();
      data.release();
      super.dispose();
    }
  }
}