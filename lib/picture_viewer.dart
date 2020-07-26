
import 'dart:async';

import 'package:cache_image/cache_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/core/array.dart';
import 'package:glib/core/callback.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/models.dart';
import 'package:kinoko/configs.dart';
import 'package:kinoko/utils/cached_picture_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:glib/main/error.dart' as glib;
import 'package:glib/utils/bit64.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'utils/preload_queue.dart';

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
  int index = 0;
  int touchState = 0;
  bool appBarDisplay = true;
  Offset downPosition;
  MethodChannel channel;
  PageController pageController = PageController();
  String cacheKey;
  PreloadQueue preloadQueue;

  void onDataChanged(int type, Array data, int pos) {
    if (data != null) {
      addToPreload(data);
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

  Future<void> onVolumeButtonClicked(MethodCall call) async {
    if (call.method == "keyDown") {
      int code = call.arguments;
      switch (code) {
        case 1: {
          pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeOutCubic);
          break;
        }
        case 2: {
          pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeOutCubic);
          break;
        }
      }
    }
  }

  CachedPictureImage makeImageProvider(DataItem item) {
    if (cacheKey == null) {
      cacheKey = widget.context.projectKey + "/" + Bit64.encodeString(widget.context.info_data.link);
    }
    return CachedPictureImage(
        item.picture,
        key: cacheKey,
        maxAgeCacheObject: item.isInCollection(collection_download) ? Duration(days: 365 * 99999) : Duration(days: 30)
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
            child: data.length == 0 ?
            Center(
              child: SpinKitRing(
                lineWidth: 4,
                size: 36,
                color: Colors.white,
              ),
            ):
            PhotoViewGallery.builder(
              itemCount: data.length,
              pageController: pageController,
              builder: (BuildContext context, int index) {
                DataItem item = data[index];
                return PhotoViewGalleryPageOptions(
                    imageProvider: makeImageProvider(item),
                    initialScale: PhotoViewComputedScale.contained,
                    onTapUp: (c0, c1, c2) {
                      setState(() {
                        appBarDisplay = !appBarDisplay;
                      });
                    }
                  // heroAttributes: HeroAttributes(tag: galleryItems[index].id),
                );
              },
              gaplessPlayback: true,
              loadingBuilder: (context, event) {
                return Center(
                  child: SpinKitRing(
                    lineWidth: 4,
                    size: 36,
                    color: Colors.white,
                  ),
                );
              },

              onPageChanged: (idx) {
                setState(() {
                  index = idx;
                });
              },
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
                  child: Text(
                    widget.context.info_data.title,
                    style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white),
                  )
                ),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert, color: Colors.white,),
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
            top: appBarDisplay ? media.padding.top : (-44),
            left: media.padding.left,
            right: media.padding.right,
            height: 44,
            duration: Duration(milliseconds: 300),
          ),

          Positioned(
            child: AnimatedOpacity(
              child: Text(
                data.length > 0 ? "${index + 1}/${data.length}" : "",
                style: Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.white),
              ),
              opacity: appBarDisplay ? 1 : 0,
              duration: Duration(milliseconds: 300)
            ),
            right: 10 + media.padding.right,
            bottom: 36 + media.padding.bottom,
          ),

        ],
      )
    );
  }

  @override
  initState() {
    preloadQueue = PreloadQueue();

    widget.context.control();
    widget.context.on_data_changed = Callback.fromFunction(onDataChanged).release();
    widget.context.on_loading_status = Callback.fromFunction(onLoadingStatus).release();
    widget.context.on_error = Callback.fromFunction(onError).release();
    widget.context.enterView();
    data = widget.context.data.control();
    channel = MethodChannel("com.ero.kinoko/volume_button");
    channel.invokeMethod("start");
    channel.setMethodCallHandler(onVolumeButtonClicked);
    super.initState();
  }

  @override
  dispose() {
    preloadQueue.stop();
    widget.context.exitView();
    data?.release();
    widget.context.release();
    channel?.invokeMethod("stop");
    super.dispose();
  }

  void addToPreload(Array arr) {
    for (int i = 0 ,t = arr.length; i < t; ++i) {
      DataItem item = arr[i];
      print("added " + item.picture);
      preloadQueue.add(makeImageProvider(item));
    }
  }
}