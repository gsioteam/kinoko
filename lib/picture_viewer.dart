
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
import 'utils/download_manager.dart';
import 'utils/preload_queue.dart';
import 'dart:math' as math;
import 'package:gesture_zoom_box/gesture_zoom_box.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'localizations/localizations.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

enum PictureFlipType {
  Next,
  Prev
}

class PictureViewer extends StatefulWidget {
  Context context;
  Context Function(PictureFlipType) onChapterChanged;

  PictureViewer(this.context, this.onChapterChanged);

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
  PageController pageController;
  AutoScrollController scrollController;
  String cacheKey;
  PreloadQueue preloadQueue;
  bool loading = false;
  bool isTap = false;
  Timer _timer;
  bool isHorizontal = true;
  PictureCacheManager _cacheManager;

  void onDataChanged(int type, Array data, int pos) {
    if (data != null) {
      addToPreload(data);
      setState(() {});
    }
  }

  void onLoadingStatus(bool isLoading) {
    setState(() {
      loading = isLoading;
    });
  }

  void onError(glib.Error error) {
    Fluttertoast.showToast(
      msg: error.msg,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  void pageNext() {
    if (isHorizontal) {
      pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    } else {
      index++;
      print("To $index");
      scrollController.scrollToIndex(index);
    }
  }

  void pagePrev() {
    if (isHorizontal) {
      pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    } else {
      index--;
      print("To $index");
      scrollController.scrollToIndex(index);
    }
  }

  Future<void> onVolumeButtonClicked(MethodCall call) async {
    if (call.method == "keyDown") {
      int code = call.arguments;
      switch (code) {
        case 1: {
          if (!loading) {
            if (pageController.page < data.length - 1) {
              pageNext();
            } else {
              Context context;
              if (widget.onChapterChanged != null && (context = widget.onChapterChanged(PictureFlipType.Next)) != null) {
                untouch();
                widget.context = context;
                touch();
                pageController.jumpTo(0);
                setState(() { });
              } else {
                pageNext();
              }
            }
          } else {
            pageNext();
          }
          break;
        }
        case 2: {
          if (pageController.page > 0) {
            pagePrev();
          } else {
            Context context;
            if (widget.onChapterChanged != null && (context = widget.onChapterChanged(PictureFlipType.Prev)) != null) {
              untouch();
              widget.context = context;
              touch();
              pageController.jumpTo(math.max(data.length.toDouble() - 1, 0));
              setState(() { });
            } else {
              pagePrev();
            }
          }
          break;
        }
      }
    }
  }

  PictureCacheManager get cacheManager {
    if (_cacheManager == null) {
      DataItem item = widget.context.info_data;
      if (cacheKey == null) {
        cacheKey = widget.context.projectKey + "/" + Bit64.encodeString(widget.context.info_data.link);
      }
      _cacheManager = PictureCacheManager(cacheKey, maxAgeCacheObject: item.isInCollection(collection_download) ? Duration(days: 365 * 99999) : Duration(days: 30));
    }
    return _cacheManager;
  }

  CachedNetworkImageProvider makeImageProvider(DataItem item) {
    return CachedNetworkImageProvider(
      item.picture,
      cacheManager: cacheManager
    );
  }

  void onTapScreen() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
    setState(() {
      appBarDisplay = !appBarDisplay;
    });
  }

  Widget buildPager(BuildContext context) {
    if (isHorizontal) {
      return PhotoViewGallery.builder(
        itemCount: data.length,
        pageController: pageController,
        builder: (BuildContext context, int index) {
          DataItem item = data[index];
          return PhotoViewGalleryPageOptions(
            imageProvider: makeImageProvider(item),
            initialScale: PhotoViewComputedScale.contained,
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
      );
    } else {

      return ListView.builder(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 44
        ),
        controller: scrollController,
        itemBuilder: (context, index) {
          DataItem item = data[index];
          return AutoScrollTag(
            key: ValueKey(index),
            controller: scrollController,
            index: index,
            child: Container(
              constraints: BoxConstraints(
                  minHeight: 560
              ),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                  color: Colors.black
              ),
              padding: EdgeInsets.only(top: 2, bottom: 2),
              child: Center(
                child: GestureZoomBox(
                  maxScale: 5.0,
                  doubleTapScale: 2.0,
                  child: CachedNetworkImage(
                    imageUrl: item.picture,
                    cacheManager: cacheManager,
                    fit: BoxFit.fitWidth,
                    placeholder: (context, url) {
                      return SpinKitRing(
                        lineWidth: 4,
                        size: 36,
                        color: Colors.white,
                      );
                    },
                    errorWidget: (context, url, error) {
                      return Icon(Icons.broken_image);
                    },
                  ),
                ),
              ),
            )
          );
        },
        itemCount: data.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData media = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Listener(
            child: Container(
              color: Colors.black,
              child: data.length == 0 ?
              Center(
                child: SpinKitRing(
                  lineWidth: 4,
                  size: 36,
                  color: Colors.white,
                ),
              ):
              NotificationListener<OverscrollNotification>(
                child: buildPager(context),
                onNotification: (notification) {
                  print("overscroll ${notification.overscroll}");
                  return false;
                },
              ),
            ),
            onPointerDown: (event) {
              isTap = true;
              downPosition = event.localPosition;
            },
            onPointerMove: (event) {
              if ((event.localPosition - downPosition).distance > 3) {
                isTap = false;
              }
            },
            onPointerUp: (event) {
              if (isTap) {
                onTapScreen();
              }
            },
          ),

          AnimatedPositioned(
            child: Container(
              color: Colors.black26,
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
                        return <PopupMenuEntry>[
                          PopupMenuItem(
                            child: FlatButton(
                              onPressed: () {
                                if (!isHorizontal) {
                                  setState(() {
                                    isHorizontal = true;
                                  });
                                }
                              },
                              child: Row(
                                children: <Widget>[
                                  Icon(Icons.border_vertical),
                                  Container(
                                    padding: EdgeInsets.only(left: 20),
                                    child: Text(kt("horizontal_flip")),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            child: FlatButton(
                              onPressed: () {
                                if (isHorizontal) {
                                  setState(() {
                                    isHorizontal = false;
                                  });
                                }
                              },
                              child: Row(
                                children: <Widget>[
                                  Icon(Icons.border_horizontal),
                                  Container(
                                    padding: EdgeInsets.only(left: 20),
                                    child: Text("vertical"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          PopupMenuDivider(),
                          PopupMenuItem(
                            child: FlatButton(
                                onPressed: () {

                                },
                                child: Row(
                                  children: <Widget>[
                                    Icon(Icons.stay_current_portrait),
                                    Container(
                                      padding: EdgeInsets.only(left: 20),
                                      child: Text("portrait"),
                                    ),
                                  ],
                                )
                            ),
                          ),
                          PopupMenuItem(
                            child: FlatButton(
                                onPressed: () {

                                },
                                child: Row(
                                  children: <Widget>[
                                    Icon(Icons.stay_current_landscape),
                                    Container(
                                      padding: EdgeInsets.only(left: 20),
                                      child: Text("landscape"),
                                    ),
                                  ],
                                )
                            ),
                          ),
                          PopupMenuDivider(),
                          PopupMenuItem(
                            child: FlatButton(
                                onPressed: () {

                                },
                                child: Row(
                                  children: <Widget>[
                                    Icon(Icons.file_download),
                                    Container(
                                      padding: EdgeInsets.only(left: 20),
                                      child: Text("download"),
                                    ),
                                  ],
                                )
                            ),
                          ),
                        ];
                      }
                  )
                ],
              ),
            ),
            top: appBarDisplay ? media.padding.top : (-44),
            left: media.padding.left,
            right: media.padding.right,
            height: 44,
            duration: Duration(milliseconds: 300),
          ),

          Positioned(
            child: AnimatedOpacity(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: data.length > 0 ? "${index + 1}/${data.length}" : "",
                      style: Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.white),
                    ),
                    WidgetSpan(child: Container(padding: EdgeInsets.only(left: 5),)),
                    WidgetSpan(
                      child: AnimatedOpacity(
                        opacity: loading ? 1 : 0,
                        duration: Duration(milliseconds: 300),
                        child: SpinKitFoldingCube(
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      alignment: PlaceholderAlignment.middle
                    )
                  ]
                ),
                style: TextStyle(
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(1, 1)
                    )
                  ]
                ),
              ) ,
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

  void touch() {
    preloadQueue = PreloadQueue();
    widget.context.control();
    widget.context.on_data_changed = Callback.fromFunction(onDataChanged).release();
    widget.context.on_loading_status = Callback.fromFunction(onLoadingStatus).release();
    widget.context.on_error = Callback.fromFunction(onError).release();
    widget.context.enterView();
    data = widget.context.data.control();
  }

  void untouch() {
    widget.context.on_data_changed = null;
    widget.context.on_loading_status = null;
    widget.context.on_error = null;
    widget.context.exitView();
    data?.release();
    widget.context.release();
    preloadQueue.stop();
  }

  @override
  initState() {
    _timer = Timer(Duration(seconds: 5), () {
      setState(() {
        appBarDisplay = false;
      });
    });
    pageController = PageController();
    scrollController = AutoScrollController();

    touch();
    channel = MethodChannel("com.ero.kinoko/volume_button");
    channel.invokeMethod("start");
    channel.setMethodCallHandler(onVolumeButtonClicked);
    super.initState();
  }

  @override
  dispose() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
    pageController.dispose();
    scrollController.dispose();
    untouch();
    channel?.invokeMethod("stop");
    super.dispose();
  }

  void addToPreload(Array arr) {
    for (int i = 0 ,t = arr.length; i < t; ++i) {
      DataItem item = arr[i];
      print("added " + item.picture);
      preloadQueue.add(DownloadPictureItem(item.picture, cacheManager));
    }
  }
}