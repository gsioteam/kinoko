
import 'package:flutter/material.dart';

import '../../utils/neo_cache_manager.dart';
import '../images/one_finger_zoom_gesture_recognizer.dart';
import '../images/photo_image.dart';
import '../over_drag.dart';
import 'pager.dart';

class InkScreenPager extends Pager {
  final OneFingerCallback? onTap;

  InkScreenPager({
    Key? key,
    NeoCacheManager? cacheManager,
    this.onTap,
    required PagerController controller,
    required int itemCount,
    required ImageFetcher imageUrlProvider
  }) : super(
    key: key,
    cacheManager:  cacheManager,
    controller: controller,
    itemCount: itemCount,
    imageUrlProvider: imageUrlProvider
  );

  @override
  PagerState<Pager> createState() => InkScreenPagerState();

}

class InkScreenPagerState extends PagerState<InkScreenPager> {

  Map<int, PhotoImageController> _pages = new Map();
  int index = 0;

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context);
    PhotoInformation photoInformation = widget.imageUrlProvider(index);
    PhotoImageController controller = getPageController(index);

    return OverDrag(
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
            color: Colors.black
        ),
        child: Center(
          child: !photoInformation.hasData ?
          Container() : PhotoImage(
            imageProvider: photoInformation.getImageProvider(widget.cacheManager),
            size: media.size,
            animationDuration: Duration.zero,
            loadingWidget: (context) {
              return Container();
            },
            errorWidget: (context) {
              return Icon(
                Icons.broken_image,
                color: Colors.white,
              );
            },
            onTap: widget.onTap,
            controller: controller,
          ),
        ),
      ),
      left: true,
      right: true,
      onOverDrag: (type) {
        if (type == OverDragType.Left) {
          widget.controller.onOverBound?.call(BoundType.Start);
        } else if (type == OverDragType.Right) {
          widget.controller.onOverBound?.call(BoundType.End);
        }
      },
    );
  }

  PhotoImageController getPageController(int index) {
    if (_pages.containsKey(index)) {
      return _pages[index]!;
    } else {
      _pages[index] = PhotoImageController();
      return _pages[index]!;
    }
  }

  @override
  void onNext() {
    var controller = getPageController(index);
    if (controller.arriveEnd()) {
      if (index >= widget.itemCount - 1) {
        widget.controller.onOverBound?.call(BoundType.End);
      } else {
        setState(() {
          index += 1;
        });
      }
    } else {
      controller.next();
    }
  }

  @override
  void onPrev() {
    var controller = getPageController(index);
    if (controller.arriveStart()) {
      if (index <= 0) {
        widget.controller.onOverBound?.call(BoundType.Start);
      } else {
        setState(() {
          index -= 1;
        });
      }
    } else {
      controller.prev();
    }
  }

  @override
  void onPage(int page, bool animate) {
    setState(() {
      index = page;
    });
  }

}