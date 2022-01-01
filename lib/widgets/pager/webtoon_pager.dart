
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/change_notifier.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:kinoko/utils/neo_cache_manager.dart';
import 'package:kinoko/widgets/images/one_finger_zoom_gesture_recognizer.dart';
import 'package:kinoko/widgets/over_drag.dart';
import 'package:kinoko/widgets/pager/pager.dart';
import 'package:my_scrollable_positioned_list/my_scrollable_positioned_list.dart';
import '../images/zoom_image.dart';
import 'dart:math' as math;

const double _DefaultBarHeight = 88;
const double _PageAlignment = 0.1;

class WebtoonPager extends Pager {

  final OneFingerCallback? onTap;

  WebtoonPager({
    Key? key,
    required NeoCacheManager cacheManager,
    required PagerController controller,
    required int itemCount,
    required PhotoInformation Function(int index) imageUrlProvider,
    this.onTap,
  }) : super(
    key: key,
    cacheManager: cacheManager,
    controller: controller,
    itemCount: itemCount,
    imageUrlProvider: imageUrlProvider,
  );

  @override
  PagerState<Pager> createState() => WebtoonPagerState();
}

class WebtoonPagerState extends PagerState<WebtoonPager> {

  late ItemScrollController controller;
  late ItemPositionsListener listener;
  bool _listen = true;
  ItemPosition? _current;

  @override
  Widget build(BuildContext context) {
    return OverDrag(
      child: buildScrollable(context),
      up: true,
      down: true,
      onOverDrag: (type) {
        if (type == OverDragType.Up) {
          widget.controller.onOverBound?.call(BoundType.Start);
        } else if (type == OverDragType.Down) {
          widget.controller.onOverBound?.call(BoundType.End);
        }
      },
    );
  }

  Widget buildScrollable(BuildContext context) {
    return ScrollablePositionedList.builder(
      padding: EdgeInsets.symmetric(
          vertical: _DefaultBarHeight
      ),
      itemCount: widget.itemCount,
      initialScrollIndex: widget.controller.index,
      initialAlignment: _PageAlignment,
      itemScrollController: controller,
      itemPositionsListener: listener,
      itemBuilder: (context, index) {
        PhotoInformation photoInformation = widget.imageUrlProvider(index);

        return photoInformation.url == null ?
        SpinKitRing(
          lineWidth: 4,
          size: 36,
          color: Colors.white,
        ) : ZoomImage(
          imageProvider: NeoImageProvider(
            uri: Uri.parse(photoInformation.url!),
            cacheManager: widget.cacheManager,
            headers: photoInformation.headers,
          ),
          loadingWidget: (context) {
            return SpinKitRing(
              lineWidth: 4,
              size: 36,
              color: Colors.white,
            );
          },
          errorWidget: (context) {
            return Icon(
              Icons.broken_image,
              color: Colors.white,
            );
          },
          onTap: widget.onTap,
        );
      },
    );
  }

  @override
  void onNext() async {
    if (_current != null) {
      int target;
      double alignment;
      var current = _current!;
      if (current.itemTrailingEdge > 1) {
        target = current.index;
        var len = current.itemTrailingEdge - current.itemLeadingEdge;
        alignment = math.max(current.itemLeadingEdge - 0.6, (1 - _PageAlignment)-len);
      } else {
        if (current.index < widget.itemCount - 1) {
          target = current.index + 1;
          alignment = _PageAlignment;
        } else {
          widget.controller.onOverBound?.call(BoundType.End);
          return;
        }
      }
      controller.scrollTo(
        index: target,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: alignment,
      );
    }
  }

  @override
  void onPrev() {
    if (_current != null) {
      int target;
      double alignment;
      var current = _current!;
      if (current.itemLeadingEdge < 0) {
        target = current.index;
        // var len = _current.itemTrailingEdge - _current.itemLeadingEdge;
        alignment = math.min(current.itemLeadingEdge + 0.6, _PageAlignment);
      } else {
        if (current.index > 0) {
          target = current.index;
          alignment = 1 - _PageAlignment;
        } else {
          widget.controller.onOverBound?.call(BoundType.Start);
          return;
        }
      }
      controller.scrollTo(
        index: target,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: alignment,
      );

    }
  }

  @override
  void onPage(int page, bool animate) {
    if (animate) {
      _listen = false;
      controller.scrollTo(
          index: page,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          alignment: 0.1
      ).then((value) => _listen = true);
    } else {
      controller.jumpTo(
        index: page,
        alignment: _PageAlignment,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    controller = ItemScrollController();
    listener = ItemPositionsListener.create();
    listener.itemPositions.addListener(_positionUpdate);
    _initPosition();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WebtoonPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initPosition();
  }

  void _positionUpdate() {
    if (!_listen) return;
    var list = listener.itemPositions.value;
    ItemPosition? current;
    double space = 0;
    for (var position in list) {
      var size = math.min(1.0, position.itemTrailingEdge) - math.max(0.0, position.itemLeadingEdge);
      if (size > space) {
        space = size;
        current = position;
      }
    }
    if (current != null) {
      _current = current;
      setPage(current.index);
    }
  }

  void _initPosition() {
    if (widget.controller.index == -1 && widget.itemCount > 0) {
      widget.controller.index = widget.itemCount - 1;
      if (controller.isAttached) {
        controller.jumpTo(
          index: widget.itemCount - 1,
          alignment: -99,
        );
      }
    }
  }
}