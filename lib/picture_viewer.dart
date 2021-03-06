
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/core/array.dart';
import 'package:glib/core/callback.dart';
import 'package:glib/core/gmap.dart';
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
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'utils/download_manager.dart';
import 'utils/preload_queue.dart';
import 'dart:math' as math;
import 'package:gesture_zoom_box/gesture_zoom_box.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'localizations/localizations.dart';
import 'widgets/photo_list.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'utils/data_item_headers.dart';
import 'dart:ui' as ui;

enum PictureFlipType {
  Next,
  Prev
}

class HorizontalIconPainter extends CustomPainter {

  final Color textColor;

  HorizontalIconPainter(this.textColor);

  @override
  void paint(Canvas canvas, Size size) {
    drawIcon(canvas, Icons.border_vertical, Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.translate(size.width, 0);
    canvas.scale(-1, 1);
    double inset = size.width * 0.05;
    drawIcon(canvas, Icons.arrow_right_alt_sharp, Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2));
  }

  void drawIcon(Canvas canvas, IconData icon, Rect rect) {
    var builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontFamily: icon.fontFamily,
    ))
      ..pushStyle(ui.TextStyle(
        color: textColor,
        fontSize: rect.width
      ))
      ..addText(String.fromCharCode(icon.codePoint));
    var para = builder.build();
    para.layout(ui.ParagraphConstraints(width: rect.width));
    canvas.drawParagraph(para, Offset(rect.left, rect.top));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is HorizontalIconPainter) {
      return oldDelegate.textColor != textColor;
    } else {
      return true;
    }
  }
}

// ignore: must_be_immutable
class PictureViewer extends StatefulWidget {
  Context context;
  final Context Function(PictureFlipType) onChapterChanged;
  final int startPage;
  final void Function(DataItem) onDownload;

  PictureViewer(this.context, {
    this.onChapterChanged,
    this.onDownload,
    this.startPage
  });

  @override
  State<StatefulWidget> createState() {
    return _PictureViewerState();
  }
}

enum FlipType {
  Horizontal,
  HorizontalReverse,
  Vertical,
}

class _PictureViewerState extends State<PictureViewer> {

  Array data;
  int index = 0;
  int touchState = 0;
  bool appBarDisplay = true;
  Offset downPosition;
  MethodChannel channel;
  String cacheKey;
  PreloadQueue preloadQueue;
  bool loading = false;
  bool isTap = false;
  Timer _timer;
  PictureCacheManager _cacheManager;
  PhotoController photoController;
  FlipType flipType = FlipType.Horizontal;
  bool isLandscape = false;

  String _directionKey;
  String _deviceKey;
  String _pageKey;
  bool _firstTime = true;

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
    photoController.next();
  }

  void pagePrev() {
    photoController.prev();
  }

  Future<void> onVolumeButtonClicked(MethodCall call) async {
    if (call.method == "keyDown") {
      int code = call.arguments;
      switch (code) {
        case 1: {
          pageNext();
          break;
        }
        case 2: {
          pagePrev();
          break;
        }
      }
    }
  }

  PictureCacheManager get cacheManager {
    if (_cacheManager == null) {
      DataItem item = widget.context.info_data;
      _cacheManager = PictureCacheManager(
        cacheKey, item
      );
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
    if (_firstTime && widget.startPage != null) {
      photoController.index = math.max(math.min(widget.startPage, data.length - 1), 0);
      index = photoController.index;
      preloadQueue.offset = index;
    }
    _firstTime = false;
    return PhotoList(
      key: photoController?.key,
      itemCount: data.length,
      imageUrlProvider: (int index) {
        DataItem item = (data[index] as DataItem);
        return PhotoInformation(item.picture, item.headers);
      },
      flipType: flipType,
      controller: photoController,
      cacheManager: cacheManager,
      appBarHeight: appBarDisplay ? 44 : 0,
    );
  }

  void showPagePicker() {
    if (!appBarDisplay) {
      setState(() {
        appBarDisplay = true;
      });
      return;
    }
    List<PickerItem<int>> items = [];
    for (int i = 0, t= data.length; i < t; ++i) {
      items.add(PickerItem<int>(
        text: Text(kt("n_page").replaceAll("{0}", (i + 1).toString())),
        value: i,
      ));
    }

    new Picker(
      adapter: PickerDataAdapter<int>(
        data: items
      ),
      selecteds: [index],
      onConfirm: (picker, values) {
        photoController.animateTo(values[0]);
      }
    ).showModal(context);
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData media = MediaQuery.of(context);
    double size = IconTheme.of(context).size;
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
              buildPager(context),
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
                      List<PopupMenuEntry> list = [
                        PopupMenuItem(
                          child: TextButton(
                            onPressed: () {
                              if (flipType != FlipType.Horizontal) {
                                setState(() {
                                  flipType = FlipType.Horizontal;
                                });
                                KeyValue.set(_directionKey, "horizontal");
                                Navigator.of(context).pop();
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
                            style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all(flipType != FlipType.Horizontal ? Colors.blue : Colors.black87)
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          child: TextButton(
                            onPressed: () {
                              if (flipType != FlipType.HorizontalReverse) {
                                setState(() {
                                  flipType = FlipType.HorizontalReverse;
                                });
                                KeyValue.set(_directionKey, "horizontal_reverse");
                                Navigator.of(context).pop();
                              }
                            },
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: size,
                                  height: size,
                                  child: CustomPaint(
                                    painter: HorizontalIconPainter(flipType != FlipType.HorizontalReverse ? Colors.blue : Colors.black87),
                                    size: Size(size, size),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.only(left: 20),
                                  child: Text(kt("horizontal_reverse")),
                                ),
                              ],
                            ),
                            style: ButtonStyle(
                                foregroundColor: MaterialStateProperty.all(flipType != FlipType.HorizontalReverse ? Colors.blue : Colors.black87)
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          child: TextButton(
                            onPressed: () {
                              if (flipType != FlipType.Vertical) {
                                setState(() {
                                  flipType = FlipType.Vertical;
                                });
                                KeyValue.set(_directionKey, "vertical");
                                Navigator.of(context).pop();
                              }
                            },
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.border_horizontal),
                                Container(
                                  padding: EdgeInsets.only(left: 20),
                                  child: Text(kt("vertical_flip")),
                                ),
                              ],
                            ),
                            style: ButtonStyle(
                                foregroundColor: MaterialStateProperty.all(flipType != FlipType.Vertical ? Colors.blue : Colors.black87)
                            ),
                          ),
                        ),
                        PopupMenuDivider(),
                        PopupMenuItem(
                          child: TextButton(
                            onPressed: () {
                              if (isLandscape) {
                                setState(() {
                                  isLandscape = false;
                                  updateOrientation();
                                });
                                KeyValue.set(_deviceKey, "portrait");
                                Navigator.of(context).pop();
                              }
                            },
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.stay_current_portrait),
                                Container(
                                  padding: EdgeInsets.only(left: 20),
                                  child: Text(kt("portrait")),
                                ),
                              ],
                            ),
                            style: ButtonStyle(
                                foregroundColor: MaterialStateProperty.all(isLandscape ? Colors.blue : Colors.black87)
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          child: TextButton(
                            onPressed: () {
                              if (!isLandscape) {
                                setState(() {
                                  isLandscape = true;
                                  updateOrientation();
                                });
                                KeyValue.set(_deviceKey, "landscape");
                                Navigator.of(context).pop();
                              }
                            },
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.stay_current_landscape),
                                Container(
                                  padding: EdgeInsets.only(left: 20),
                                  child: Text(kt("landscape")),
                                ),
                              ],
                            ),
                            style: ButtonStyle(
                                foregroundColor: MaterialStateProperty.all(!isLandscape ? Colors.blue : Colors.black87)
                            ),
                          ),
                        ),
                      ];

                      if (widget.onDownload != null) {
                        list.add(PopupMenuDivider());
                        list.add(PopupMenuItem(
                          child: TextButton(
                            onPressed: () {
                              widget.onDownload(widget.context.info_data);
                              Navigator.of(context).pop();
                            },
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.file_download),
                                Container(
                                  padding: EdgeInsets.only(left: 20),
                                  child: Text(kt("download")),
                                ),
                              ],
                            )
                          ),
                        ));
                      }
                      return list;
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
              child: TextButton(
                onPressed: showPagePicker,
                child: Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        child: Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.toc, color: Colors.white,size: 16,),
                        ),
                        alignment: PlaceholderAlignment.middle
                      ),
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
                ),
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

  void touch() {
    cacheKey = PictureCacheManager.cacheKey(widget.context.info_data);
    preloadQueue = PreloadQueue();
    widget.context.control();
    widget.context.on_data_changed = Callback.fromFunction(onDataChanged).release();
    widget.context.on_loading_status = Callback.fromFunction(onLoadingStatus).release();
    widget.context.on_error = Callback.fromFunction(onError).release();
    widget.context.enterView();
    data = widget.context.data.control();
    loadSavedData();
  }

  void untouch() {
    widget.context.on_data_changed = null;
    widget.context.on_loading_status = null;
    widget.context.on_error = null;
    widget.context.exitView();
    data?.release();
    widget.context.release();
    preloadQueue.stop();
    loading = false;
  }

  void onPage(index) {
    setState(() {
      this.index = index;
    });
    preloadQueue.offset = index;
    KeyValue.set(_pageKey, index.toString());
  }

  void updateOrientation() {
    if (isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  void loadSavedData() {
    String key = widget.context.projectKey;
    _directionKey = "$direction_key:$key";
    _deviceKey = "$device_key:$key";
    _pageKey = "$page_key:$cacheKey";
    String direction = KeyValue.get(_directionKey);
    switch (direction) {
      case 'vertical': {
        flipType = FlipType.Vertical;
        break;
      }
      case 'horizontal': {
        flipType = FlipType.Horizontal;
        break;
      }
      case 'horizontal_reverse': {
        flipType = FlipType.HorizontalReverse;
        break;
      }
      default: {
        flipType = FlipType.Horizontal;
      }
    }
    String device = KeyValue.get(_deviceKey);
    isLandscape = device == "landscape";
    String pageStr = KeyValue.get(_pageKey);
    if (pageStr != null) {
      try {
        index = int.parse(pageStr);
      } catch (e) {
      }
    }
  }

  bool _toastCoolDown = true;

  void onOverBound(BoundType type) {
    if (type == BoundType.Start) {
      Context context;
      if (widget.onChapterChanged != null && (context = widget.onChapterChanged(PictureFlipType.Prev)) != null) {
        untouch();
        widget.context = context;
        touch();
        setState(() {
          index = math.max(data.length - 1, 0);
          photoController?.dispose();
          photoController  = PhotoController(
              onPage: onPage,
              index: index,
              onOverBound: onOverBound
          );
          // photoController.pageController.jumpToPage(index);
          if (!appBarDisplay) {
            appBarDisplay = true;
            willDismissAppBar();
          }
        });
      } else if (_toastCoolDown) {
        _toastCoolDown = false;
        Fluttertoast.showToast(msg: kt("no_prev_chapter"), toastLength: Toast.LENGTH_SHORT);
        Future.delayed(Duration(seconds: 3)).then((value) => _toastCoolDown = true);
      }
    } else if (!loading) {
      Context context;
      if (widget.onChapterChanged != null && (context = widget.onChapterChanged(PictureFlipType.Next)) != null) {
        untouch();
        widget.context = context;
        touch();
        setState(() {
          index = 0;
          photoController?.dispose();
          photoController = PhotoController(
              onPage: onPage,
              index: index,
              onOverBound: onOverBound
          );
          if (!appBarDisplay) {
            appBarDisplay = true;
            willDismissAppBar();
          }
        });
      } else if (_toastCoolDown) {
        _toastCoolDown = false;
        Fluttertoast.showToast(msg: kt("no_next_chapter"), toastLength: Toast.LENGTH_SHORT);
        Future.delayed(Duration(seconds: 3)).then((value) => _toastCoolDown = true);
      }
    }
  }

  willDismissAppBar() {
    _timer = Timer(Duration(seconds: 4), () {
      setState(() {
        appBarDisplay = false;
      });
    });
  }

  @override
  initState() {

    touch();
    willDismissAppBar();
    photoController = PhotoController(
      onPage: onPage,
      index: index,
      onOverBound: onOverBound
    );
    updateOrientation();
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
    photoController.dispose();
    untouch();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    channel?.invokeMethod("stop");
    super.dispose();
  }

  void addToPreload(Array arr) {
    for (int i = 0 ,t = arr.length; i < t; ++i) {
      DataItem item = arr[i];
      preloadQueue.set(i, DownloadPictureItem(item.picture, cacheManager, headers: item.headers));
    }
  }
}