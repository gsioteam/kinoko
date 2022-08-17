
import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/main/models.dart';
import 'package:kinoko/configs.dart';
import 'package:kinoko/utils/plugin/manga_loader.dart';
import 'package:kinoko/utils/plugin/plugin.dart';
import 'package:kinoko/widgets/pager/flip_pager.dart';
import 'package:kinoko/widgets/pager/horizontal_pager.dart';
import 'package:kinoko/widgets/pager/ink_screen_pager.dart';
import 'package:kinoko/widgets/pager/webtoon_pager.dart';
import 'package:kinoko/widgets/picture_hint_painter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:quds_popup_menu/quds_popup_menu.dart';
import '../utils/download_manager.dart';
import '../utils/neo_cache_manager.dart';
import '../utils/preload_queue.dart';
import 'dart:math' as math;
import '../localizations/localizations.dart';
import '../widgets/instructions_dialog.dart';
import '../widgets/navigator.dart';
import '../widgets/page_slider.dart';
import '../widgets/pager/pager.dart';
import 'dart:ui' as ui;
import '../utils/fullscreen.dart';
import '../widgets/pager/vertical_pager.dart';
import '../utils/picture_data.dart';

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

  final PictureData data;
  final int? page;

  PictureViewer({
    Key? key,
    required this.data,
    this.page,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PictureViewerState();
  }
}

enum FlipType {
  Horizontal,
  HorizontalReverse,
  RightToLeft,
  Vertical,
  Webtoon,
  Flip,
  InkScreen,
}

enum PagerTransitionDirection {
  Prev,
  None,
  Next
}

HintMatrix _hintMatrix(FlipType type) {
  switch (type) {
    case FlipType.Flip:
    case FlipType.InkScreen:
    case FlipType.Horizontal: {
      return HintMatrix([
        -1, 0, 1,
        -1, 0, 1,
        -1, 0, 1,
      ]);
    }
    case FlipType.HorizontalReverse: {
      return HintMatrix();
    }
    case FlipType.RightToLeft: {
      return HintMatrix([
        1, 0, -1,
        1, 0, -1,
        1, 0, -1,
      ]);
    }
    case FlipType.Vertical:
    case FlipType.Webtoon:
      {
      return HintMatrix([
        -1, -1, -1,
        -1,  0,  1,
         1,  1,  1,
      ]);
    }
    default: {
      throw Exception("Unkown type $type");
    }
  }
}

class _PagerKey extends LocalKey {
  final Orientation orientation;
  final Object value;

  _PagerKey(this.value, this.orientation);

  @override
  bool operator ==(Object other) {
    if (other is _PagerKey) {
      return other.orientation == orientation && other.value == value;
    }
    return super == other;
  }

  @override
  int get hashCode => 0x98808000 | orientation.hashCode << 16 | value.hashCode;

}

class _PictureViewerState extends State<PictureViewer> {

  int index = 0;
  int touchState = 0;
  bool appBarDisplay = true;
  static MethodChannel _channel = MethodChannel("com.ero.kinoko/volume_button");
  bool loading = false;
  Timer? _timer;
  late PagerController pagerController;
  FlipType flipType = FlipType.Horizontal;
  bool isLandscape = false;

  GlobalKey iconKey = GlobalKey();

  late PictureController dataController;

  late String _directionKey;
  late String _deviceKey;
  late String _pageKey;
  bool _hintDisplay = false;

  GlobalKey<PageSliderState> _sliderKey = GlobalKey();

  GlobalKey _canvasKey = GlobalKey();

  late ValueNotifier<SystemUiOverlayStyle> _uiOverlayStyle;

  void onLoadingStatus(bool isLoading) {
    setState(() {
      loading = isLoading;
    });
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

  void setAppBarDisplay(display) {
    setState(() {
      appBarDisplay = display;
      // SystemChrome.setEnabledSystemUIOverlays(display ? SystemUiOverlay.values : []);
      if (display) {
        exitFullscreen();
      } else {
        enterFullscreen();
        _sliderKey.currentState?.dismiss();
        _hintTimer?.cancel();
        _hintDisplay = false;
      }
    });
  }

  void onTapScreen() {
    _timer?.cancel();
    _timer = null;
    setAppBarDisplay(!appBarDisplay);
  }

  Widget buildPager(BuildContext context, Orientation orientation) {
    var controller = dataController;
    switch (flipType) {
      case FlipType.Horizontal:
      case FlipType.HorizontalReverse: {
        return HorizontalPager(
          key: _PagerKey(pagerController, orientation),
          reverse: flipType == FlipType.HorizontalReverse,
          cacheManager: dataController.cacheManager,
          controller: pagerController,
          itemCount: dataController.length,
          imageUrlProvider: (int index) {
            return controller.getPicture(index);
          },
          onTap: (event) {
            tapAt(event.position);
          },
        );
      }
      case FlipType.RightToLeft: {
        return HorizontalPager(
          key: _PagerKey(pagerController, orientation),
          cacheManager: dataController.cacheManager,
          controller: pagerController,
          itemCount: dataController.length,
          imageUrlProvider: (int index) {
            return dataController.getPicture(index);
          },
          onTap: (event) {
            tapAt(event.position);
          },
          direction: AxisDirection.left,
        );
      }
      case FlipType.Vertical: {
        return VerticalPager(
          key: _PagerKey(pagerController, orientation),
          cacheManager: dataController.cacheManager,
          controller: pagerController,
          itemCount: dataController.length,
          imageUrlProvider: (int index) {
            return dataController.getPicture(index);
          },
          onTap: (event) {
            tapAt(event.position);
          },
        );
      }
      case FlipType.Webtoon: {
        return WebtoonPager(
          key: _PagerKey(pagerController, orientation),
          cacheManager: dataController.cacheManager,
          controller: pagerController,
          itemCount: dataController.length,
          imageUrlProvider: (int index) {
            return dataController.getPicture(index);
          },
          onTap: (event) {
            tapAt(event.position);
          },
        );
      }
      case FlipType.Flip: {
        return FlipPager(
          key: _PagerKey(pagerController, orientation),
          cacheManager: dataController.cacheManager,
          controller: pagerController,
          itemCount: dataController.length,
          imageUrlProvider: (int index) {
            return dataController.getPicture(index);
          },
          onTap: (event) {
            tapAt(event.position);
          },
        );
      }
      case FlipType.InkScreen: {
        return InkScreenPager(
          key: _PagerKey(pagerController, orientation),
          cacheManager: dataController.cacheManager,
          controller: pagerController,
          itemCount: dataController.length,
          imageUrlProvider: (int index) {
            return dataController.getPicture(index);
          },
          onTap: (event) {
            tapAt(event.position);
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
    double size = IconTheme.of(context).size ?? 36;

    void setFlipType(FlipType type, String name) {
      if (flipType != type && NavigatorConfig.navigatorType != NavigatorType.InkScreen) {
        setState(() {
          flipType = FlipType.Horizontal;
        });
        displayHint();
        KeyValue.set(_directionKey, "horizontal");
      }
    }

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
                onPressed: () {
                  setFlipType(FlipType.Horizontal, 'horizontal');
                },
            ),
            QudsPopupMenuItem(
                leading: Container(
                  width: size,
                  height: size,
                  child: CustomPaint(
                    painter: HorizontalIconPainter(
                        Theme.of(context).iconTheme.color??Colors.black87,
                    ),
                    size: Size(size, size),
                  ),
                ),
                title: Text(kt("horizontal_reverse")),
                trailing: flipType == FlipType.HorizontalReverse ?
                Icon(Icons.check) : null,
                onPressed: () {
                  setFlipType(FlipType.HorizontalReverse, 'horizontal_reverse');
                },
            ),
            QudsPopupMenuItem(
              leading: Transform.rotate(
                angle: math.pi,
                child: Icon(Icons.arrow_right_alt),
                alignment: Alignment.center,
              ),
              title: Text(kt("right_to_left")),
              trailing: flipType == FlipType.RightToLeft ?
              Icon(Icons.check) : null,
              onPressed: () {
                setFlipType(FlipType.RightToLeft, 'right_to_left');
              },
            ),
            QudsPopupMenuItem(
                leading: Icon(Icons.border_horizontal),
                title: Text(kt('vertical_flip')),
                trailing: flipType == FlipType.Vertical ?
                Icon(Icons.check) : null,
                onPressed: () {
                  setFlipType(FlipType.Vertical, 'vertical');
                },
            ),

            QudsPopupMenuItem(
              leading: Icon(Icons.web_asset_sharp),
              title: Text(kt('webtoon')),
              trailing: flipType == FlipType.Webtoon ?
              Icon(Icons.check) : null,
              onPressed: () {
                setFlipType(FlipType.Webtoon, 'webtoon');
              },
            ),

            QudsPopupMenuItem(
              leading: Icon(Icons.web_asset_sharp),
              title: Text(kt('flip')),
              trailing: flipType == FlipType.Flip ?
              Icon(Icons.check) : null,
              onPressed: () {
                setFlipType(FlipType.Flip, 'flip');
              },
            ),
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
                onPressed: () {
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
                onPressed: () {
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
    // if (widget.onDownload != null) {
    //   menuItems.add(QudsPopupMenuItem(
    //       leading: Icon(Icons.file_download),
    //       title: Text(kt('download')),
    //       onPressed: () {
    //         widget.onDownload(pictureContext.infoData);
    //         Fluttertoast.showToast(msg: kt('added_download').replaceAll('{0}', "1"));
    //       }
    //   ),);
    // }
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
    var currentBody = OrientationBuilder(
      key: ValueKey(pagerController),
      builder: (context, orientation) {
        return buildPager(context, orientation);
      }
    );

    return WillPopScope(
      child: ValueListenableBuilder<SystemUiOverlayStyle>(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.black,
          body: Stack(
            children: <Widget>[
              GestureDetector(
                key: _canvasKey,
                child: Container(
                    color: Colors.black,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: dataController.length == 0 ?
                          Center(
                            child: SpinKitRing(
                              lineWidth: 4,
                              size: 36,
                              color: Colors.white,
                            ),
                          ):
                          AnimatedSwitcher(
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeOutCubic,
                            duration: NavigatorConfig.duration,
                            child: currentBody,
                            transitionBuilder: (child, animation) {
                              switch (_pageDirection) {
                                case PagerTransitionDirection.None:
                                  return child;
                                default: {
                                  var size = MediaQuery.of(context).size;
                                  Offset from;
                                  int sign = 1;
                                  if (child != currentBody)
                                    sign *= -1;
                                  if (_pageDirection == PagerTransitionDirection.Prev)
                                    sign *= -1;
                                  if (flipType == FlipType.Vertical || flipType == FlipType.Webtoon) {
                                    from = Offset(0,
                                        sign * size.height
                                    );
                                  } else if (flipType == FlipType.RightToLeft) {
                                    from = Offset(sign * -size.width, 0);
                                  } else {
                                    from = Offset(sign * size.width, 0);
                                  }
                                  return AnimatedBuilder(
                                    animation: animation,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset.lerp(from, Offset.zero, animation.value)!,
                                        child: child,
                                      );
                                    },
                                    child: child,
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedOpacity(
                              opacity: _hintDisplay ? 1 : 0,
                              duration: NavigatorConfig.duration,
                              child: CustomPaint(
                                painter: PictureHintPainter(
                                    matrix: _hintMatrix(flipType),
                                    prevText: kt("prev"),
                                    menuText: kt("menu"),
                                    nextText: kt("next")
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                ),
                onTapUp: (event) {
                  tapAt(event.localPosition);
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
                          onPressed: () async {
                            _uiOverlayStyle.value = Theme.of(context).appBarTheme.systemOverlayStyle!;
                            await Future.delayed(Duration(milliseconds: 20));
                            Navigator.of(context).pop();
                          }
                      ),
                      Expanded(
                          child: Text(
                            dataController.title,
                            style: Theme.of(context).textTheme.headline6?.copyWith(color: Colors.white),
                            maxLines: 1,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
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
                duration: NavigatorConfig.duration,
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
                                text: dataController.length > 0 ? "${index == -1 ? dataController.length : (index + 1)}/${dataController.length}" : "",
                                style: Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.white),
                              ),
                              WidgetSpan(child: Container(padding: EdgeInsets.only(left: 5),)),
                              WidgetSpan(
                                  child: AnimatedOpacity(
                                    opacity: loading ? 1 : 0,
                                    duration: NavigatorConfig.duration,
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
                    duration: NavigatorConfig.duration
                ),
                right: 10 + padding.right,
                bottom: Platform.isIOS ? padding.bottom : 0,
              ),

              Positioned(
                child: index == -1 ? Container() : PageSlider(
                  key: _sliderKey,
                  total: dataController.length,
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
                bottom: (Platform.isIOS ? padding.bottom : 0) + 6,
                left: 10 + padding.left,
                height: 40,
              ),
            ],
          ),
        ),
        builder: (context, value, child) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            child: child!,
            value: value,
          );
        },
        valueListenable: _uiOverlayStyle,
      ),
      onWillPop: () async {
        _uiOverlayStyle.value = Theme.of(context).appBarTheme.systemOverlayStyle!;
        await Future.delayed(Duration(milliseconds: 20));
        return true;
      }
    );
  }

  void touch() {
    loadSavedData();
  }

  void _update() {
    setState(() {
    });
  }

  void onPage(index) {
    try {
      setState(() {
        this.index = index;
      });
    } catch (e) {
      this.index = index;
    }
    dataController.onPage(index);
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
    String key = widget.data.key;
    _directionKey = "$direction_key:$key";
    _deviceKey = "$device_key:$key";
    _pageKey = "$page_key:${dataController.cacheManager?.key ?? key}";
    if (NavigatorConfig.navigatorType == NavigatorType.InkScreen) {
      flipType = FlipType.InkScreen;
    } else {
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
        case 'right_to_left': {
          flipType = FlipType.RightToLeft;
          break;
        }
        case 'webtoon': {
          flipType = FlipType.Webtoon;
          break;
        }
        case 'flip': {
          flipType = FlipType.Flip;
          break;
        }
        default: {
          flipType = FlipType.Horizontal;
        }
      }
    }
    String device = KeyValue.get(_deviceKey);
    isLandscape = device == "landscape";
    String pageStr = KeyValue.get(_pageKey);
    index = int.tryParse(pageStr) ?? 0;
  }

  bool _toastCoolDown = true;
  PagerTransitionDirection _pageDirection = PagerTransitionDirection.None;

  void onOverBound(BoundType type) {
    if (type == BoundType.Start) {
      if (dataController.hasPrev) {
        dataController.goPrev();
        touch();
        setState(() {
          index = - 1;
          pagerController.dispose();
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
          _pageDirection = PagerTransitionDirection.Prev;
        });
      } else if (_toastCoolDown) {
        _toastCoolDown = false;
        Fluttertoast.showToast(msg: kt("no_prev_chapter"), toastLength: Toast.LENGTH_SHORT);
        Future.delayed(Duration(seconds: 3)).then((value) => _toastCoolDown = true);
      }
    } else if (!loading) {
      if (dataController.hasNext) {
        dataController.goNext();
        touch();
        setState(() {
          index = 0;
          pagerController.dispose();
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
          _pageDirection = PagerTransitionDirection.Next;
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
    dataController = widget.data.createController();
    dataController.addListener(_update);
    loading = dataController.loading.value;
    dataController.addListener(() {
      onLoadingStatus(dataController.loading.value);
    });

    _uiOverlayStyle = ValueNotifier(SystemUiOverlayStyle.dark.copyWith(
      systemNavigationBarDividerColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarColor: Colors.black26,
    ));

    touch();
    if (widget.page != null) {
      index = widget.page!;
    }
    willDismissAppBar();
    pagerController = PagerController(
      onPage: onPage,
      index: index,
      onOverBound: onOverBound
    );
    updateOrientation();
    _channel.invokeMethod("start");
    _channel.setMethodCallHandler(onVolumeButtonClicked);
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
    _uiOverlayStyle.dispose();
    _timer?.cancel();
    _timer = null;
    pagerController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _channel.invokeMethod("stop");
    dataController.dispose();
    super.dispose();
  }

  Timer? _hintTimer;
  void displayHint() {
    _hintTimer?.cancel();
    setState(() {
      _hintDisplay = true;
    });
    _hintTimer = Timer(Duration(seconds: 4), () {
      setState(() {
        _hintDisplay = false;
      });
    });
  }

  void tapAt(Offset position) {
    var rect = _canvasKey.currentContext?.findRenderObject()?.semanticBounds;
    if (rect == null) {
      onTapScreen();
    } else {
      var matrix = _hintMatrix(flipType);
      int ret = matrix.findValue(rect.size, position);
      if (ret > 0) {
        pagerController.next();
      } else if (ret < 0) {
        pagerController.prev();
      } else {
        onTapScreen();
      }
    }
  }
}