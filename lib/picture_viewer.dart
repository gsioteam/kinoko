
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
import 'package:kinoko/widgets/pager/horizontal_pager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:glib/main/error.dart' as glib;
import 'package:glib/utils/bit64.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:quds_popup_menu/quds_popup_menu.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'main.dart';
import 'utils/download_manager.dart';
import 'utils/neo_cache_manager.dart';
import 'utils/preload_queue.dart';
import 'dart:math' as math;
import 'package:gesture_zoom_box/gesture_zoom_box.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'localizations/localizations.dart';
import 'widgets/instructions_dialog.dart';
import 'widgets/page_slider.dart';
import 'widgets/pager/pager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'utils/data_item_headers.dart';
import 'dart:ui' as ui;
import 'utils/fullscreen.dart';
import 'widgets/pager/vertical_pager.dart';

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

class PictureViewer extends StatefulWidget {
  Context context;
  final Context Function(PictureFlipType) onChapterChanged;
  final int startPage;
  final void Function(DataItem) onDownload;

  PictureViewer(this.context, {
    this.onChapterChanged,
    this.onDownload,
    this.startPage,
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
  NeoCacheManager _cacheManager;
  PagerController pagerController;
  FlipType flipType = FlipType.Horizontal;
  bool isLandscape = false;

  GlobalKey iconKey = GlobalKey();

  String _directionKey;
  String _deviceKey;
  String _pageKey;
  bool _firstTime = true;

  GlobalKey<PageSliderState> _sliderKey = GlobalKey();

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
    pagerController.next();
  }

  void pagePrev() {
    pagerController.prev();
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

  NeoCacheManager get cacheManager {
    if (_cacheManager == null) {
      // DataItem item = widget.context.infoData;
      _cacheManager = NeoCacheManager(cacheKey);
    }
    return _cacheManager;
  }

  NeoImageProvider makeImageProvider(DataItem item) {
    return NeoImageProvider(
      uri: Uri.parse(item.picture),
      cacheManager: cacheManager
    );
  }

  void setAppBarDisplay(display) {
    setState(() {
      appBarDisplay = display;
      // SystemChrome.setEnabledSystemUIOverlays(display ? SystemUiOverlay.values : []);
      if (display) {
        exitFullscreen();
      } else {
        enterFullscreen();
        _sliderKey.currentState?.dismiss();
      }
    });

  }

  void onTapScreen() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
    setAppBarDisplay(!appBarDisplay);
  }

  Widget buildPager(BuildContext context) {
    if (_firstTime && widget.startPage != null) {
      pagerController.index = math.max(math.min(widget.startPage, data.length - 1), 0);
      index = pagerController.index;
      preloadQueue.offset = index;
    }
    _firstTime = false;
    switch (flipType) {
      case FlipType.Horizontal:
      case FlipType.HorizontalReverse: {
        return HorizontalPager(
          key: ValueKey(pagerController),
          reverse: flipType == FlipType.HorizontalReverse,
          cacheManager: cacheManager,
          controller: pagerController,
          itemCount: data.length,
          imageUrlProvider: (int index) {
            DataItem item = (data[index] as DataItem);
            return PhotoInformation(item.picture, item.headers);
          },
        );
      }
      case FlipType.Vertical: {
        return VerticalPager(
          key: ValueKey(pagerController),
          cacheManager: cacheManager,
          controller: pagerController,
          itemCount: data.length,
          imageUrlProvider: (int index) {
            DataItem item = (data[index] as DataItem);
            return PhotoInformation(item.picture, item.headers);
          },
        );
      }
      default: {
        return Container();
      }
    }
  }

  void showPagePicker() {
    if (!appBarDisplay) {
      setAppBarDisplay(true);
      return;
    }

    _sliderKey.currentState?.show();
  }

  @override
  Widget build(BuildContext context) {
    double size = IconTheme.of(context).size;

    List<QudsPopupMenuBase> menuItems = [
      QudsPopupMenuSection(
          titleText: kt("page_mode"),
          leading: Icon(
            Icons.flip,
          ),
          subItems: [
            QudsPopupMenuItem(
                leading: Icon(Icons.border_vertical),
                title: Text(kt("horizontal_flip")),
                trailing: flipType == FlipType.Horizontal ?
                Icon(Icons.check) : null,
                onPressed: flipType == FlipType.Horizontal ? null : () {
                  if (flipType != FlipType.Horizontal) {
                    setState(() {
                      flipType = FlipType.Horizontal;
                    });
                    KeyValue.set(_directionKey, "horizontal");
                  }
                }
            ),
            QudsPopupMenuItem(
                leading: Container(
                  width: size,
                  height: size,
                  child: CustomPaint(
                    painter: HorizontalIconPainter(flipType != FlipType.HorizontalReverse ? Colors.black87 : Colors.blue),
                    size: Size(size, size),
                  ),
                ),
                title: Text(kt("horizontal_reverse")),
                trailing: flipType == FlipType.HorizontalReverse ?
                Icon(Icons.check) : null,
                onPressed: flipType == FlipType.HorizontalReverse ? null : () {
                  if (flipType != FlipType.HorizontalReverse) {
                    setState(() {
                      flipType = FlipType.HorizontalReverse;
                    });
                    KeyValue.set(_directionKey, "horizontal_reverse");
                  }
                }
            ),
            QudsPopupMenuItem(
                leading: Icon(Icons.border_horizontal),
                title: Text(kt('vertical_flip')),
                trailing: flipType == FlipType.Vertical ?
                Icon(Icons.check) : null,
                onPressed: () {
                  if (flipType != FlipType.Vertical) {
                    setState(() {
                      flipType = FlipType.Vertical;
                    });
                    KeyValue.set(_directionKey, "vertical");
                  }
                }
            )
          ]
      ),
      QudsPopupMenuSection(
          leading: isLandscape ? Icon(Icons.stay_current_landscape) : Icon(Icons.stay_current_portrait),
          titleText: kt('orientation'),
          subItems: [
            QudsPopupMenuItem(
                leading: Icon(Icons.stay_current_portrait),
                title: Text(kt("portrait")),
                trailing: !isLandscape ?
                Icon(Icons.check) : null,
                onPressed: !isLandscape ? null : () {
                  if (isLandscape) {
                    setState(() {
                      isLandscape = false;
                      updateOrientation();
                    });
                    KeyValue.set(_deviceKey, "portrait");
                  }
                }
            ),
            QudsPopupMenuItem(
                leading: Icon(Icons.stay_current_landscape),
                title: Text(kt("landscape")),
                trailing: isLandscape ?
                Icon(Icons.check) : null,
                onPressed: isLandscape ? null : () {
                  if (!isLandscape) {
                    setState(() {
                      isLandscape = true;
                      updateOrientation();
                    });
                    KeyValue.set(_deviceKey, "landscape");
                  }
                }
            ),
          ]
      ),
    ];
    if (widget.onDownload != null) {
      menuItems.add(QudsPopupMenuItem(
          leading: Icon(Icons.file_download),
          title: Text(kt('download')),
          onPressed: () {
            widget.onDownload(widget.context.infoData);
            Fluttertoast.showToast(msg: kt('added_download').replaceAll('{0}', "1"));
          }
      ),);
    }
    menuItems.add(QudsPopupMenuItem(
        leading: Icon(
          Icons.help_outline,
          key: iconKey,
        ),
        title: Text(kt("instructions")),
        onPressed: () {
          showInstructionsDialog(context, 'assets/picture',
            entry: kt('lang'),
            iconColor: Theme.of(context).primaryColor,
          );
        }
    ),);

    var padding = MediaQuery.of(context).padding;

    return AnnotatedRegion<SystemUiOverlayStyle>(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.black,
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
                            widget.context.infoData.title,
                            style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white),
                          )
                      ),
                      QudsPopupButton(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: 10,
                          ),
                          child: Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                        ),
                        items: menuItems,
                      ),
                    ],
                  ),
                ),
                top: appBarDisplay ? padding.top : (-44),
                left: padding.left,
                right: padding.right,
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
                right: 10 + padding.right,
                bottom: 0,
              ),

              Positioned(
                child: PageSlider(
                  key: _sliderKey,
                  total: data.length,
                  page: index,
                  onPage: (page) {
                    setState(() {
                      index = page;
                    });
                    return pagerController.animateTo(page);
                  },
                  onAppear: () {
                    _timer?.cancel();
                    _timer = null;
                  },
                ),
                right: 26 + padding.right,
                bottom: 6,
                left: 10 + padding.left,
                height: 40,
              ),
            ],
          ),
        ),
        value: SystemUiOverlayStyle.dark.copyWith(
          systemNavigationBarDividerColor: Colors.black,
        ),
    );
  }

  void touch() {
    cacheKey = NeoCacheManager.cacheKey(widget.context.infoData);
    preloadQueue = PreloadQueue();
    widget.context.control();
    widget.context.onDataChanged = Callback.fromFunction(onDataChanged).release();
    widget.context.onLoadingStatus = Callback.fromFunction(onLoadingStatus).release();
    widget.context.onError = Callback.fromFunction(onError).release();
    widget.context.enterView();
    data = widget.context.data.control();
    loadSavedData();
  }

  void untouch() {
    widget.context.onDataChanged = null;
    widget.context.onLoadingStatus = null;
    widget.context.onError = null;
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
          pagerController?.dispose();
          pagerController  = PagerController(
              onPage: onPage,
              index: index,
              onOverBound: onOverBound,
          );
          // photoController.pageController.jumpToPage(index);
          if (!appBarDisplay) {
            appBarDisplay = true;
            // SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
            exitFullscreen();
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
          pagerController?.dispose();
          pagerController = PagerController(
              onPage: onPage,
              index: index,
              onOverBound: onOverBound,
          );
          if (!appBarDisplay) {
            appBarDisplay = true;
            // SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
            exitFullscreen();
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
      setAppBarDisplay(false);
    });
  }

  @override
  initState() {
    touch();
    willDismissAppBar();
    pagerController = PagerController(
      onPage: onPage,
      index: index,
      onOverBound: onOverBound
    );
    updateOrientation();
    channel = MethodChannel("com.ero.kinoko/volume_button");
    channel.invokeMethod("start");
    channel.setMethodCallHandler(onVolumeButtonClicked);
    super.initState();

    if (KeyValue.get("$viewed_key:picture") != "true") {
      Future.delayed(Duration(milliseconds: 300)).then((value) async {
        await showInstructionsDialog(context, 'assets/picture',
          entry: kt('lang'),
          iconColor: Theme.of(context).primaryColor,
          onPop: null,
          //     () async {
          //   // menuKey.currentState.showButtonMenu();
          //   await Future.delayed(Duration(milliseconds: 300));
          //   final renderObject = iconKey.currentContext.findRenderObject();
          //   Rect rect = renderObject?.paintBounds;
          //   var translation = renderObject?.getTransformTo(null)?.getTranslation();
          //   if (rect != null && translation != null) {
          //     return rect.shift(Offset(translation.x, translation.y));
          //   }
          //   return null;
          // }
        );
        KeyValue.set("$viewed_key:picture", "true");
        // if (menuKey.currentState.mounted)
        //   Navigator.of(menuKey.currentContext).pop();
      });
    }
  }

  @override
  dispose() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
    pagerController.dispose();
    untouch();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    channel?.invokeMethod("stop");
    super.dispose();
    // SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
  }

  void addToPreload(Array arr) {
    for (int i = 0 ,t = arr.length; i < t; ++i) {
      DataItem item = arr[i];
      preloadQueue.set(i, DownloadPictureItem(item.picture, cacheManager, headers: item.headers));
    }
  }
}