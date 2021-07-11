
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:kinoko/picture_viewer.dart';
import 'package:kinoko/utils/neo_cache_manager.dart';
import 'dart:math' as math;
import 'over_drag.dart';
import 'dart:ui' as ui;
import 'package:vector_math/vector_math_64.dart' as m64;

enum BoundType {
  Start,
  End
}

class _PageRange {
  double start = 0;
  double get length => 1;
  double end = 1;
  bool reverse = false;

  static int ANIMATE = 1;
  static int SET_START = 2;

  bool arriveStart() => start <= 0;
  bool arriveEnd() =>  start + length >= end;

  List<void Function(double, int)> listeners = List();

  void addListener(void Function(double, int) listener) {
    listeners.add(listener);
  }

  void removeListener(void Function(double, int) listener) {
    listeners.remove(listener);
  }

  void onOffset(double offset, int state) {
    for (var ls in listeners) {
      ls(offset, state);
    }
  }

}

typedef WidgetBuilder = Widget Function(BuildContext);

class PhotoImage extends StatefulWidget {
  final ImageProvider imageProvider;
  final Size size;
  final EdgeInsets padding;
  final WidgetBuilder loadingWidget;
  final WidgetBuilder errorWidget;
  final _PageRange range;
  final FlipType flipType;
  final bool initFromEnd;

  PhotoImage({
    @required this.imageProvider,
    this.size,
    this.padding,
    this.loadingWidget,
    this.errorWidget,
    @required this.range,
    this.flipType,
    this.initFromEnd = false
  });

  @override
  State<StatefulWidget> createState() => PhotoImageState();
}

class PhotoImageState extends State<PhotoImage> with TickerProviderStateMixin {

  ImageInfo _imageInfo;
  ImageStreamListener _imageStreamListener;
  ImageStream _imageStream;
  bool _hasError = false;

  AnimationController controller;

  Duration _duration = const Duration(milliseconds: 600);

  PhotoImageState() {
    _imageStreamListener = ImageStreamListener(
      _getImage,
      onError: _getError
    );
  }

  void onOffset(double offset, int state) {
    var range = widget.range;
    double value;
    if (state & _PageRange.SET_START == 0) {
      switch (widget.flipType) {
        case FlipType.Horizontal: {
          double maxWidth = widget.size.width - widget.padding.left - widget.padding.right;
          value = math.max(0, math.min(1, controller.value - (offset / maxWidth) / (range.end - range.length)));
          break;
        }
        case FlipType.HorizontalReverse: {
          double maxWidth = widget.size.width - widget.padding.left - widget.padding.right;
          value = math.max(0, math.min(1, controller.value + (offset / maxWidth) / (range.end - range.length)));
          break;
        }
        case FlipType.Vertical: {
          double maxHeight = widget.size.height - widget.padding.top - widget.padding.bottom;
          value = math.max(0, math.min(1, controller.value - (offset / maxHeight) / (range.end - range.length)));
          break;
        }
      }
    } else {
      value = offset / (range.end - range.length);
    }
    if ((state & _PageRange.ANIMATE) != 0) {
      controller.animateTo(value, duration: _duration, curve: Curves.easeOutCubic);
    } else {
      controller.value = value;
    }
  }

  Offset _translation = Offset.zero;
  double _scale = 1;

  Offset _oldOffset = Offset.zero;
  double _oldScale = 1;

  Rect _imageRect;
  Size _imageSize;

  void _onScaleStart(ScaleStartDetails details) {
    _oldOffset = details.focalPoint;
    _oldScale = 1;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_imageRect != null) {
      setState(() {
        Offset offset = details.focalPoint - _oldOffset;
        _translation += offset;
        _oldOffset = details.focalPoint;
        var disScale = details.scale / _oldScale;
        var oldScale = _scale;
        _scale *= disScale;
        if (_scale < 1) {
          _scale = 1;
          disScale = _scale / oldScale;
        } else if (_scale > 4) {
          _scale = 4;
          disScale = _scale / oldScale;
        }
        _oldScale = details.scale;

        var offSize = _imageRect.size * (disScale - 1);
        var dx = -_translation.dx, dy = -_translation.dy;
        if (widget.flipType == FlipType.Vertical) {
          dy += _imageRect.height * _oldScale * widget.range.start;
        } else {
          dx += _imageRect.width * _oldScale * widget.range.start;
        }

        dx += _imageSize.width / 2 * _oldScale;
        dy += _imageSize.height / 2 * _oldScale;

        var cSize = _imageRect.size * _oldScale;
        _translation -= Offset(offSize.width * dx / cSize.width, offSize.height * dy / cSize.height);
        clampImage();
      });
    }
  }

  void clampImage() {
    double nx = _translation.dx, ny = _translation.dy;
    if (nx > 0) {
      nx = 0;
    }
    if (ny > 0) {
      ny = 0;
    }
    var size = _imageRect.size * _scale;
    if (nx < _imageSize.width - size.width) {
      nx = _imageSize.width - size.width;
    }
    if (ny < _imageSize.height - size.height) {
      ny = _imageSize.height - size.height;
    }
    _translation = Offset(nx, ny);
    print("$_translation - ${_imageSize} $size" );
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_imageRect != null) {

    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        child: Center(
          child: widget.errorWidget?.call(context),
        ),
      );
    } else {
      ui.Image image = _imageInfo?.image;
      double width, height;
      if (image != null) {
        double left = widget.padding.left, top = widget.padding.top,
            maxWidth = widget.size.width - widget.padding.left - widget.padding.right,
            maxHeight = widget.size.height - widget.padding.top - widget.padding.bottom;
        switch (widget.flipType) {
          case FlipType.Horizontal:
          case FlipType.HorizontalReverse: {
            if (image.width / image.height < 1) {
              width = maxWidth;
              height = maxWidth * image.height / image.width;
              widget.range.end = 1;
              widget.range.start = 0;
            } else {
              height = maxHeight - 60;
              width = height * image.width / image.height;
              widget.range.end = width / maxWidth;
              widget.range.start = 0;
            }
            widget.range.reverse = widget.flipType == FlipType.HorizontalReverse;
            break;
          }
          case FlipType.Vertical: {
            width = maxWidth;
            height = maxWidth * image.height / image.width;
            widget.range.end = math.max(1, height / maxHeight);
            widget.range.reverse = false;
            break;
          }
        }

        if (maxWidth > width) {
          left = (maxWidth - width) / 2 + widget.padding.left;
        }
        if (maxHeight > height) {
          top = (maxHeight - height) / 2 + widget.padding.top;
        }

        _imageRect = Rect.fromLTWH(left, top, width, height);
        _imageSize = Size(widget.size.width - left * 2, widget.size.height - top * 2);

        return GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              var range = widget.range;
              range.start = controller.value * (range.end - range.length);
              double tLeft = left, tTop = top;
              switch (widget.flipType) {
                case FlipType.Horizontal: {
                  tLeft -= range.start * maxWidth;
                  break;
                }
                case FlipType.HorizontalReverse: {
                  tLeft -= (range.end - range.length - range.start) * maxWidth;
                  break;
                }
                case FlipType.Vertical: {
                  tTop -= range.start * maxHeight;
                  break;
                }
              }
              return Stack(
                children: [
                  Positioned(
                      left: tLeft,
                      top: tTop,
                      width: width,
                      height: height,
                      child: Transform(
                        transform: Matrix4.translation(m64.Vector3(_translation.dx, _translation.dy, 0))
                          ..scale(_scale, _scale),
                        child: child,
                      )
                  )
                ],
              );
            },
            child: Container(
              color: Colors.black,
              width: width,
              height: height,
              padding: EdgeInsets.all(1),
              child: RawImage(
                image: _imageInfo?.image,
                width: width - 2,
                height: height - 2,
                fit: BoxFit.fill,
              ),
            ),
          ),
        );

      } else {
        return Container(
          width: widget.size.width,
          child: Center(
            child: widget.loadingWidget?.call(context),
          ),
        );
      }
    }
  }

  void _getImage(ImageInfo image, bool synchronousCall) {
    setState(() {
      _imageInfo = image;
    });
  }

  void _getError(dynamic exception, StackTrace stackTrace) {
    setState(() {
      _hasError = true;
    });
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateImage();
  }

  @override
  void initState() {
    super.initState();
    widget.range.addListener(onOffset);
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300)
    );

    controller.value = widget.initFromEnd ? 1 : 0;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
    _imageStream?.removeListener(_imageStreamListener);
    widget.range.removeListener(onOffset);
  }

  @override
  void didUpdateWidget(PhotoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider) {
      _updateImage();
    }
    if (widget.range != oldWidget.range) {
      oldWidget.range.removeListener(onOffset);
      widget.range.addListener(onOffset);
    }
  }

  void _updateImage() {
    final ImageStream oldImageStream = _imageStream;
    _imageStream = widget.imageProvider.resolve(createLocalImageConfiguration(context));
    if (_imageStream.key != oldImageStream?.key) {
      _hasError = false;
      oldImageStream?.removeListener(_imageStreamListener);
      _imageStream.addListener(_imageStreamListener);
    }
  }
}

class _PageScrollPhysics extends PageScrollPhysics {
  final PhotoController controller;
  _PageScrollPhysics({ ScrollPhysics parent, this.controller }) : super(parent: parent);

  @override
  _PageScrollPhysics applyTo(ScrollPhysics ancestor) {
    return _PageScrollPhysics(parent: buildParent(ancestor), controller: controller);
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    var page = controller.pageController.page;
    var round = page.round();
    var range = controller.getPageRange(round);
    if (offset <= 0 && (page < round || (!range.reverse && range.arriveEnd() || range.reverse && range.arriveStart()))) {
      return super.applyPhysicsToUserOffset(position, offset);
    } else if (offset > 0 && (page > round || (!range.reverse && range.arriveStart() || range.reverse && range.arriveEnd()))) {
      return super.applyPhysicsToUserOffset(position, offset);
    } else {
      range.onOffset(offset, 0);
      return 0;
    }
  }

  @override
  Simulation createBallisticSimulation(ScrollMetrics position, double velocity) {
    var range = controller.getPageRange(controller.pageController.page.round());
    if (velocity > 0 && !range.arriveEnd()) {
      range.onOffset(-velocity / 10, _PageRange.ANIMATE);
      velocity = 0;
    } else if (velocity < 0 && !range.arriveStart()) {
      range.onOffset(-velocity / 10, _PageRange.ANIMATE);
      velocity = 0;
    }
    return super.createBallisticSimulation(position, velocity);
  }
}

class PhotoController {
  int index;
  PageController _pageController;
  _PageScrollPhysics _scrollPhysics;
  void Function(int) onPage;
  _PhotoListState state;
  Key key = GlobalKey();
  void Function(BoundType) onOverBound;
  bool listen = true;
  Map<int, _PageRange> _ranges = new Map();

  static const Duration _duration = const Duration(milliseconds: 300);

  PhotoController({
    this.index = 0,
    this.onPage,
    this.onOverBound
  });

  onPageScroll() {
    if (!listen) return;
    int idx = (_pageController.page + 0.5).toInt();
    if (index != idx) {
      index = idx;
      this.onPage?.call(index);
    }
  }

  void dispose() {
    _pageController?.dispose();
  }

  void next() {
    if (state != null && state.widget != null) {
      // var idx = index;
      // double alignment = 0;
      // for (var pos in _positionsListener.itemPositions.value) {
      //   if (pos.index == index) {
      //     if (pos.itemTrailingEdge < 1.05) {
      //       if (index >= state.widget.itemCount - 1) {
      //         onOverBound?.call(BoundType.End);
      //         return;
      //       }
      //       idx = index+1;
      //       alignment = state.widget.isHorizontal ? 0 : 0.1;
      //     } else {
      //       double des = math.min(pos.itemTrailingEdge - 1, 1);
      //       alignment = pos.itemLeadingEdge - des;
      //     }
      //   }
      // }
      // index = idx;
      // scrollController.scrollTo(index: index, alignment: alignment, duration: _duration, curve: Curves.easeOutCubic);
      _PageRange range = getPageRange(pageController.page.round());
      if (range.arriveEnd()) {
        if (index >= state.widget.itemCount - 1) {
          onOverBound?.call(BoundType.End);
        } else {
          _pageController.nextPage(duration: _duration, curve: Curves.easeInOutCubic);
        }
      } else {
        var len = range.length * 0.8;
        range.onOffset(math.min(range.start + len, range.end - len), _PageRange.ANIMATE | _PageRange.SET_START);
      }
    }
  }

  void prev() {
    if (state != null && state.widget != null) {
      // var idx = index;
      // double alignment = 0;
      // for (var pos in _positionsListener.itemPositions.value) {
      //   if (pos.index == index) {
      //     if (pos.itemLeadingEdge > -0.05) {
      //       if (index <= 0) {
      //         onOverBound?.call(BoundType.Start);
      //         return;
      //       }
      //       idx = index;
      //       alignment = state.widget.isHorizontal ? 1 : 0.9;
      //     } else {
      //       double des = math.min(-pos.itemLeadingEdge, 1);
      //       alignment = pos.itemLeadingEdge + des;
      //     }
      //   }
      // }
      // index = idx;
      // scrollController.scrollTo(index: index, alignment: alignment, duration: _duration, curve: Curves.easeOutCubic);
      _PageRange range = getPageRange(pageController.page.round());
      if (range.arriveStart()) {
        if (index <= 0) {
          onOverBound?.call(BoundType.Start);
        } else {
          _pageController.previousPage(duration: _duration, curve: Curves.easeInOutCubic);
        }
      } else {
        var len = range.length * 0.8;
        range.onOffset(math.max(0, range.start - len), _PageRange.ANIMATE | _PageRange.SET_START);
      }
    }
  }

  void jumpTo(int index) {
    if (state != null && state.widget != null) {
      this.index = index;
      listen = false;
      // if (state.widget.isHorizontal) {
        pageController.jumpToPage(index);
      // } else {
      //   scrollController.jumpTo(index: this.index, alignment: state.widget.isHorizontal ? 0 : 0.1);
      // }

      listen = true;
    }
  }

  void animateTo(int index) {
    if (state != null && state.widget != null) {
      this.index = index;
      listen = false;
      // if (state.widget.isHorizontal) {
        pageController.animateToPage(index, duration: _duration, curve: Curves.easeInOutCubic);
      // } else {
      //   scrollController.scrollTo(index: this.index, alignment: state.widget.isHorizontal ? 0 : 0.1, duration: Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
      // }
      listen = true;
    }
  }

  void _touch(_PhotoListState state) {
    this.state = state;
  }

  void _untouch() {
    this.state = null;
  }

  void reset() {
    if (_pageController != null) {
      _pageController.dispose();
      _pageController = null;
    }
    _ranges.forEach((key, value) {
      value.reverse = false;
      value.start = 0;
      value.end = 1;
    });
  }

  PageController get pageController {
    if (_pageController == null) {
      _pageController = PageController(initialPage: index);
      _pageController.addListener(onPageScroll);
    }
    return _pageController;
  }

  _PageScrollPhysics get scrollPhysics {
    if (_scrollPhysics == null) {
      _scrollPhysics = _PageScrollPhysics(controller: this);
    }
    return _scrollPhysics;
  }

  _PageRange getPageRange(int index) {
    if (_ranges.containsKey(index)) {
      return _ranges[index];
    } else {
      _ranges[index] = _PageRange();
      return _ranges[index];
    }
  }
}

class PhotoInformation {
  String url;
  Map<String, String> headers;

  PhotoInformation(this.url, [this.headers]);
}

class PhotoList extends StatefulWidget {
  final FlipType flipType;
  final int itemCount;
  final PhotoInformation Function(int index) imageUrlProvider;
  final void Function(int index) onPageChanged;
  final NeoCacheManager cacheManager;
  PhotoController controller;
  final double appBarHeight;

  PhotoList({
    Key key,
    this.flipType = FlipType.Horizontal,
    @required this.imageUrlProvider,
    this.onPageChanged,
    this.cacheManager,
    this.controller,
    this.itemCount,
    this.appBarHeight = 0,
  }) : super(key: key) {
    if (controller == null) {
      controller = PhotoController();
    }
  }

  @override
  State<StatefulWidget> createState() => _PhotoListState();

}

class _PhotoInfo {
  ImageProvider provider;
}

class _PhotoListState extends State<PhotoList> {

  List<_PhotoInfo> photos = [];

  Widget buildScrollable(BuildContext context) {
    var media = MediaQuery.of(context);

    AxisDirection axisDirection = widget.flipType != FlipType.Vertical ? AxisDirection.right : AxisDirection.down;
    return Scrollable(
        axisDirection: axisDirection,
        controller: widget.controller.pageController,
        physics: widget.controller.scrollPhysics,
        viewportBuilder: (context, position) {
          return Viewport(
            offset: position,
            axisDirection: axisDirection,
            cacheExtent: 0.1,
            slivers: [
              SliverFillViewport(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    PhotoInformation photoInformation = widget.imageUrlProvider(index);
                    return Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: Colors.black
                      ),
                      child: Center(
                        child: PhotoImage(
                          imageProvider: NeoImageProvider(
                            uri: Uri.parse(photoInformation.url),
                            cacheManager: widget.cacheManager,
                            headers: photoInformation.headers,
                          ),
                          size: media.size,
                          flipType: widget.flipType,
                          padding: EdgeInsets.zero,
                          initFromEnd: index < widget.controller.index,
                          loadingWidget: (context) {
                            return SpinKitRing(
                              lineWidth: 4,
                              size: 36,
                              color: Colors.white,
                            );
                          },
                          errorWidget: (context) {
                            return Icon(Icons.broken_image);
                          },
                          range: widget.controller.getPageRange(index),
                        ),
                      ),
                    );
                  },
                    childCount: widget.itemCount
                )
              ),
            ],
          );
        }
    );
    // if (widget.isHorizontal) {
    //   return ScrollablePositionedList.builder(
    //     padding: EdgeInsets.only(
    //       top: padding.top + 44,
    //       bottom: padding.bottom
    //     ),
    //     scrollDirection: Axis.horizontal,
    //     itemCount: widget.itemCount,
    //     initialScrollIndex: widget.controller.index,
    //     itemScrollController: widget.controller.scrollController,
    //     itemPositionsListener: widget.controller.positionsListener,
    //     itemBuilder: (context, index) {
    //       PhotoInformation photoInformation = widget.imageUrlProvider(index);
    //       return Container(
    //         constraints: BoxConstraints(
    //           minWidth: media.size.width
    //         ),
    //         clipBehavior: Clip.hardEdge,
    //         decoration: BoxDecoration(
    //           color: Colors.black
    //         ),
    //         padding: EdgeInsets.only(top: 2, bottom: 2),
    //         child: Center(
    //           child: GestureZoomBox(
    //             maxScale: 5.0,
    //             doubleTapScale: 2.0,
    //             child: PhotoImage(
    //               imageProvider: CachedNetworkImageProvider(
    //                 photoInformation.url,
    //                 cacheManager: widget.cacheManager,
    //                 headers: photoInformation.headers,
    //               ),
    //               width: media.size.width,
    //               loadingWidget: (context) {
    //                 return SpinKitRing(
    //                   lineWidth: 4,
    //                   size: 36,
    //                   color: Colors.white,
    //                 );
    //               },
    //               errorWidget: (context) {
    //                 return Icon(Icons.broken_image);
    //               },
    //             ),
    //           ),
    //         ),
    //       );
    //     },
    //   );
    // } else {
    //   return ScrollablePositionedList.builder(
    //     padding: EdgeInsets.only(
    //         top: MediaQuery.of(context).padding.top + 44,
    //     ),
    //     initialScrollIndex: widget.controller.index,
    //     initialAlignment: 0.1,
    //     itemScrollController: widget.controller.scrollController,
    //     itemPositionsListener: widget.controller.positionsListener,
    //     itemBuilder: (context, index) {
    //       PhotoInformation photoInformation = widget.imageUrlProvider(index);
    //       return Container(
    //         constraints: BoxConstraints(
    //           minHeight: 560
    //         ),
    //         clipBehavior: Clip.hardEdge,
    //         decoration: BoxDecoration(
    //           color: Colors.black
    //         ),
    //         padding: EdgeInsets.only(top: 2, bottom: 2),
    //         child: Center(
    //           child: GestureZoomBox(
    //             maxScale: 5.0,
    //             doubleTapScale: 2.0,
    //             child: CachedNetworkImage(
    //               imageUrl: photoInformation.url,
    //               httpHeaders: photoInformation.headers,
    //               cacheManager: widget.cacheManager,
    //               fit: BoxFit.fitWidth,
    //               placeholder: (context, url) {
    //                 return SpinKitRing(
    //                   lineWidth: 4,
    //                   size: 36,
    //                   color: Colors.white,
    //                 );
    //               },
    //               errorWidget: (context, url, error) {
    //                 return Icon(Icons.broken_image);
    //               },
    //             ),
    //           ),
    //         ),
    //       );
    //     },
    //     itemCount: widget.itemCount,
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    return OverDrag(
      child: buildScrollable(context),
      left: widget.flipType != FlipType.Vertical,
      right: widget.flipType != FlipType.Vertical,
      up: widget.flipType == FlipType.Vertical,
      down: widget.flipType == FlipType.Vertical,
      iconInsets: EdgeInsets.only(top: widget.appBarHeight),
      onOverDrag: (OverDragType type) {
        switch (type) {
          case OverDragType.Up:
          case OverDragType.Left: {
            widget.controller?.onOverBound?.call(BoundType.Start);
            break;
          }
          case OverDragType.Down:
          case OverDragType.Right: {
            widget.controller?.onOverBound?.call(BoundType.End);
            break;
          }
          default: break;
        }
      },
    );
  }

  @override
  void didUpdateWidget(PhotoList oldWidget) {
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._untouch();
      widget.controller._touch(this);
    }
    if (widget.flipType != oldWidget.flipType) {
      widget.controller.reset();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    widget.controller._touch(this);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller._untouch();
  }
}