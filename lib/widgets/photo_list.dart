
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gesture_zoom_box/gesture_zoom_box.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:math' as math;

class PhotoController {
  int index;
  PageController pageController;
  ItemScrollController scrollController;
  ItemPositionsListener positionsListener;
  void Function(int) onPage;
  _PhotoListState state;

  static const Duration _duration = const Duration(milliseconds: 300);

  PhotoController({
    this.index = 0,
    this.onPage,
  }) {
    pageController = PageController(initialPage: index);
    scrollController = ItemScrollController();
    positionsListener = ItemPositionsListener.create();
    pageController.addListener(onPageScroll);
    positionsListener.itemPositions.addListener(onListScroll);
  }

  onPageScroll() {
    int idx = (pageController.page + 0.5).toInt();
    if (index != idx) {
      index = idx;
      this.onPage?.call(index);
    }
  }

  onListScroll() {
    int idx;
    Iterable<ItemPosition> positions = positionsListener.itemPositions.value;
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
    pageController.dispose();
  }

  void next() {
    if (state != null && state.widget != null) {
      if (state.widget.isHorizontal) {
        pageController.nextPage(duration: _duration, curve: Curves.easeOutCubic);
      } else {
        if (index < state.widget.itemCount - 1) {
          index++;
          scrollController.scrollTo(index: index, alignment: 0.1, duration: _duration, curve: Curves.easeOutCubic);
        }
      }
    }
  }

  void prev() {
    if (state != null && state.widget != null) {
      if (state.widget.isHorizontal) {
        pageController.previousPage(duration: _duration, curve: Curves.easeOutCubic);
      } else {
        if (index > 0) {
          index--;
          scrollController.scrollTo(index: index, alignment: 0.1, duration: _duration, curve: Curves.easeOutCubic);
        }
      }
    }
  }

  void jumpTo(index) {
    if (state != null && state.widget != null) {
      this.index = index;
      if (state.widget.isHorizontal) {
        pageController.jumpToPage(index);
      } else {
        scrollController.jumpTo(index: this.index, alignment: 0.1);
      }
    }
  }

  void _touch(_PhotoListState state) {
    this.state = state;
  }

  void _untouch() {
    this.state = null;
  }
}

class PhotoList extends StatefulWidget {
  bool isHorizontal;
  int itemCount;
  String Function(int index) imageUrlProvider;
  void Function(int index) onPageChanged;
  BaseCacheManager cacheManager;
  PhotoController controller;

  PhotoList({
    this.isHorizontal = true,
    @required this.imageUrlProvider,
    this.onPageChanged,
    this.cacheManager,
    this.controller,
    this.itemCount,
  }) {
    if (controller == null) {
      controller = PhotoController();
    }
  }

  @override
  State<StatefulWidget> createState() => _PhotoListState();

}

class _PhotoListState extends State<PhotoList> {

  @override
  Widget build(BuildContext context) {
    if (widget.isHorizontal) {
      return PhotoViewGallery.builder(
        itemCount: widget.itemCount,
        pageController: widget.controller.pageController,
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(
                widget.imageUrlProvider(index),
                cacheManager: widget.cacheManager
            ),
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

      );
    } else {
      return ScrollablePositionedList.builder(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 44
        ),
        initialScrollIndex: widget.controller.index,
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
  void didUpdateWidget(PhotoList oldWidget) {
    widget.controller._touch(this);
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