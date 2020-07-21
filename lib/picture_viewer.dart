
import 'package:cache_image/cache_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/core/array.dart';
import 'package:glib/core/callback.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:glib/main/error.dart' as glib;

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

  void onDataChanged(int type, Array data, int pos) {
    if (data != null) {
      setState(() {});
    }
  }

  void onLoadingStatus(bool isLoading) {
  }

  void onError(glib.Error error) {
    Fluttertoast.showToast(
      msg: error.msg,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData media = MediaQuery.of(context);
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
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
              gaplessPlayback: true,
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

          AnimatedPositioned(
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.arrow_back), 
                  color: Colors.white,
                  onPressed: () {
                    Navigator.of(context).pop();
                  }
                ),
                Expanded(
                  child: Text(widget.context.info_data.title)
                ),
                PopupMenuButton(
                  itemBuilder: (context) {
                    return <PopupMenuItem>[
                      PopupMenuItem(
                        child: Text("test"),
                      )
                    ];
                  }
                )
              ],
            ),
            top: media.padding.top,
            left: media.padding.left,
            right: media.padding.right,
            height: 44,
            duration: Duration(milliseconds: 300),
          ),
        ],
      )
    );
  }

  @override
  initState() {
    widget.context.on_data_changed = Callback.fromFunction(onDataChanged).release();
    widget.context.on_loading_status = Callback.fromFunction(onLoadingStatus).release();
    widget.context.on_error = Callback.fromFunction(onError).release();
    widget.context.enterView();
    data = widget.context.data.control();
    super.initState();
  }

  @override
  dispose() {
    widget.context.exitView();
    data.release();
    super.dispose();
  }
}