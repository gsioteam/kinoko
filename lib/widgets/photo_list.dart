
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gesture_zoom_box/gesture_zoom_box.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:math' as math;
import 'over_drag.dart';
import 'dart:ui' as ui;

enum BoundType {
  Start,
  End
}

class PhotoImage extends StatefulWidget {
  final ImageProvider imageProvider;
  final double width;

  PhotoImage({
    @required this.imageProvider,
    this.width
  });

  @override
  State<StatefulWidget> createState() => PhotoImageState();
}

class PhotoImageState extends State<PhotoImage> {

  ImageInfo _imageInfo;
  ImageStreamListener _imageStreamListener;
  ImageStream _imageStream;

  PhotoImageState() {
    _imageStreamListener = ImageStreamListener(_getImage);
  }

  @override
  Widget build(BuildContext context) {
    ui.Image image = _imageInfo?.image;
    double width;
    if (image != null) {
      if (image.width / image.height < 1) {
        width = widget.width;
      }
    }
    return RawImage(
      image: _imageInfo?.image,
      width: width,
    );
  }

  void _getImage(ImageInfo image, bool synchronousCall) {
    setState(() {
      _imageInfo = image;
    });
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateImage();
  }

  @override
  void dispose() {
    super.dispose();
    _imageStream?.removeListener(_imageStreamListener);
  }

  @override
  void didUpdateWidget(PhotoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider) {
      _updateImage();
    }
  }

  void _updateImage() {
    final ImageStream oldImageStream = _imageStream;
    _imageStream = widget.imageProvider.resolve(createLocalImageConfiguration(context));
    if (_imageStream.key != oldImageStream?.key) {

      oldImageStream?.removeListener(_imageStreamListener);
      _imageStream.addListener(_imageStreamListener);
    }
  }
}

class PhotoController {
  int index;
  PageController _pageController;
  ItemScrollController _scrollController;
  ItemPositionsListener _positionsListener;
  void Function(int) onPage;
  _PhotoListState state;
  Key key = GlobalKey();
  void Function(BoundType) onOverBound;
  bool listen = true;

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

  onListScroll() {
    if (!listen) return;
    int idx;
    Iterable<ItemPosition> positions = _positionsListener.itemPositions.value;
    for (ItemPosition pos in positions) {
      if (pos.itemLeadingEdge <= 0.5 && pos.itemTrailingEdge > 0.5) {
        idx = pos.index;
        break;
      }
    }
    if (idx == null) {
      List<ItemPosition> list = positions.toList();
      idx = list[list.length ~/ 2].index;
    }
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
      var idx = index;
      double alignment = 0;
      for (var pos in _positionsListener.itemPositions.value) {
        if (pos.index == index) {
          if (pos.itemTrailingEdge < 1.05) {
            if (index >= state.widget.itemCount - 1) {
              onOverBound?.call(BoundType.End);
              return;
            }
            idx = index+1;
            alignment = state.widget.isHorizontal ? 0 : 0.1;
          } else {
            double des = math.min(pos.itemTrailingEdge - 1, 1);
            alignment = pos.itemLeadingEdge - des;
          }
        }
      }
      index = idx;
      scrollController.scrollTo(index: index, alignment: alignment, duration: _duration, curve: Curves.easeOutCubic);
    }
  }

  void prev() {
    if (state != null && state.widget != null) {
      var idx = index;
      double alignment = 0;
      for (var pos in _positionsListener.itemPositions.value) {
        if (pos.index == index) {
          if (pos.itemLeadingEdge > -0.05) {
            if (index <= 0) {
              onOverBound?.call(BoundType.Start);
              return;
            }
            idx = index;
            alignment = state.widget.isHorizontal ? 1 : 0.9;
          } else {
            double des = math.min(-pos.itemLeadingEdge, 1);
            alignment = pos.itemLeadingEdge + des;
          }
        }
      }
      index = idx;
      scrollController.scrollTo(index: index, alignment: alignment, duration: _duration, curve: Curves.easeOutCubic);
    }
  }

  void jumpTo(int index) {
    if (state != null && state.widget != null) {
      this.index = index;
      listen = false;
      // if (state.widget.isHorizontal) {
      //   pageController.jumpToPage(index);
      // } else {
        scrollController.jumpTo(index: this.index, alignment: state.widget.isHorizontal ? 0 : 0.1);
      // }
      listen = true;
    }
  }

  void animateTo(int index) {
    if (state != null && state.widget != null) {
      this.index = index;
      listen = false;
      // if (state.widget.isHorizontal) {
      //   pageController.animateToPage(index, duration: Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
      // } else {
        scrollController.scrollTo(index: this.index, alignment: state.widget.isHorizontal ? 0 : 0.1, duration: Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
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
    _scrollController = null;
    if (_positionsListener != null) {
      _positionsListener.itemPositions.removeListener(onListScroll);
      _positionsListener = null;
    }
  }

  PageController get pageController {
    if (_pageController == null && state?.widget?.isHorizontal == true) {
      _pageController = PageController(initialPage: index);
      _pageController.addListener(onPageScroll);
    }
    return _pageController;
  }

  ItemScrollController get scrollController {
    if (_scrollController == null) {
      _scrollController = ItemScrollController();
    }
    return _scrollController;
  }

  ItemPositionsListener get positionsListener {
    if (_positionsListener == null) {
      _positionsListener = ItemPositionsListener.create();
      _positionsListener.itemPositions.addListener(onListScroll);
    }
    return _positionsListener;
  }
}

class PhotoList extends StatefulWidget {
  final bool isHorizontal;
  final int itemCount;
  final String Function(int index) imageUrlProvider;
  final void Function(int index) onPageChanged;
  final BaseCacheManager cacheManager;
  PhotoController controller;
  final double appBarHeight;

  PhotoList({
    Key key,
    this.isHorizontal = true,
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

  List<Widget> horizontalChildren(int count, Widget Function(int) builder) {
    List<Widget> list = [];
    for (int i = 0; i < count; ++i) {
      list.add(builder(i));
    }
    return list;
  }

  Widget buildScrollable(BuildContext context) {
    if (widget.isHorizontal) {
      var media = MediaQuery.of(context);
      var padding = media.padding;
      return ScrollablePositionedList.builder(
        padding: EdgeInsets.only(
          top: padding.top + 44,
          bottom: padding.bottom
        ),
        scrollDirection: Axis.horizontal,
        itemCount: widget.itemCount,
        initialScrollIndex: widget.controller.index,
        itemScrollController: widget.controller.scrollController,
        itemPositionsListener: widget.controller.positionsListener,
        itemBuilder: (context, index) {
          return Container(
            constraints: BoxConstraints(
              minWidth: media.size.width
            ),
            padding: EdgeInsets.only(top: 2, bottom: 2),
            child: Center(
              child: GestureZoomBox(
                maxScale: 5.0,
                doubleTapScale: 2.0,
                child: PhotoImage(
                  imageProvider: CachedNetworkImageProvider(
                    widget.imageUrlProvider(index),
                    cacheManager: widget.cacheManager
                  ),
                  width: media.size.width,
                ),
              ),
            ),
          );
        },
      );
    } else {
      return ScrollablePositionedList.builder(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 44,
        ),
        initialScrollIndex: widget.controller.index,
        initialAlignment: 0.1,
        itemScrollController: widget.controller.scrollController,
        itemPositionsListener: widget.controller.positionsListener,
        itemBuilder: (context, index) {
          return Container(
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
                  imageUrl: widget.imageUrlProvider(index),
                  cacheManager: widget.cacheManager,
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
          );
        },
        itemCount: widget.itemCount,
      );
    }
  }

  bool _onDragEnd(ScrollEndNotification notification) {
    if (widget.isHorizontal) {
      ItemPositionsListener positionsListener = widget.controller.positionsListener;
      for (var pos in positionsListener.itemPositions.value) {
        if (pos.index == widget.controller.index) {
          if (pos.itemLeadingEdge > 0) {
            Timer(Duration(milliseconds: 0), () {
              widget.controller.scrollController.scrollTo(
                  index: pos.index,
                  duration: Duration(milliseconds: 200),
                  alignment: 0
              );
            });
          } else if (pos.itemTrailingEdge < 1) {
            Timer(Duration(milliseconds: 0), () {
              widget.controller.scrollController.scrollTo(
                  index: pos.index,
                  duration: Duration(milliseconds: 200),
                  alignment: pos.itemLeadingEdge + (1 - pos.itemTrailingEdge)
              );
            });
          }
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollEndNotification>(
      child: OverDrag(
        child: buildScrollable(context),
        left: widget.isHorizontal,
        right: widget.isHorizontal,
        up: !widget.isHorizontal,
        down: !widget.isHorizontal,
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
      ),
      onNotification: _onDragEnd,
    );
  }

  @override
  void didUpdateWidget(PhotoList oldWidget) {
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._untouch();
      widget.controller._touch(this);
    }
    if (widget.isHorizontal != oldWidget.isHorizontal) {
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