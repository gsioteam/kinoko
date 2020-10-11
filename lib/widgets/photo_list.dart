
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gesture_zoom_box/gesture_zoom_box.dart';
import 'package:glib/core/core.dart';
import 'package:kinoko/picture_viewer.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:math' as math;
import 'over_drag.dart';

enum BoundType {
  Start,
  End
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
      idx = list[(list.length / 2).toInt()].index;
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
      if (index < state.widget.itemCount - 1) {
        if (state.widget.isHorizontal) {
          pageController.nextPage(duration: _duration, curve: Curves.easeOutCubic);
        } else {
          index++;
          scrollController.scrollTo(index: index, alignment: 0.1, duration: _duration, curve: Curves.easeOutCubic);
        }
      } else {
        onOverBound?.call(BoundType.End);
      }
    }
  }

  void prev() {
    if (state != null && state.widget != null) {
      if (index > 0) {
        if (state.widget.isHorizontal) {
          pageController.previousPage(duration: _duration, curve: Curves.easeOutCubic);
        } else {
          index--;
          scrollController.scrollTo(index: index, alignment: 0.1, duration: _duration, curve: Curves.easeOutCubic);
        }
      } else {
        onOverBound?.call(BoundType.Start);
      }
    }
  }

  void jumpTo(int index) {
    if (state != null && state.widget != null) {
      this.index = index;
      listen = false;
      if (state.widget.isHorizontal) {
        pageController.jumpToPage(index);
      } else {
        scrollController.jumpTo(index: this.index, alignment: 0.1);
      }
      listen = true;
    }
  }

  void animateTo(int index) {
    if (state != null && state.widget != null) {
      this.index = index;
      listen = false;
      if (state.widget.isHorizontal) {
        pageController.animateToPage(index, duration: Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
      } else {
        scrollController.scrollTo(index: this.index, alignment: 0.1, duration: Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
      }
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
    if (_scrollController == null && state?.widget?.isHorizontal == false) {
      _scrollController = ItemScrollController();
    }
    return _scrollController;
  }

  ItemPositionsListener get positionsListener {
    if (_positionsListener == null && state?.widget?.isHorizontal == false) {
      _positionsListener = ItemPositionsListener.create();
      _positionsListener.itemPositions.addListener(onListScroll);
    }
    return _positionsListener;
  }
}

class PhotoList extends StatefulWidget {
  bool isHorizontal;
  int itemCount;
  String Function(int index) imageUrlProvider;
  void Function(int index) onPageChanged;
  BaseCacheManager cacheManager;
  PhotoController controller;
  double appBarHeight;

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

class _PhotoListState extends State<PhotoList> {

  Widget buildScrollable(BuildContext context) {
    if (widget.isHorizontal) {
      return PageView.builder(
        itemCount: widget.itemCount,
        controller: widget.controller.pageController,
        itemBuilder: (context, index) {
          return PhotoView(
            imageProvider: CachedNetworkImageProvider(
                widget.imageUrlProvider(index),
                cacheManager: widget.cacheManager
            ),
            initialScale: PhotoViewComputedScale.contained,
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
          );
        }
      );

    } else {
      return ScrollablePositionedList.builder(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 44
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

  @override
  Widget build(BuildContext context) {
    return OverDrag(
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