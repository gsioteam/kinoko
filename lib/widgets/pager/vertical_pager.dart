
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/change_notifier.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:kinoko/utils/neo_cache_manager.dart';
import 'package:kinoko/widgets/images/one_finger_zoom_gesture_recognizer.dart';
import 'package:kinoko/widgets/images/photo_image.dart';
import 'package:kinoko/widgets/images/vertical_image.dart';
import 'package:kinoko/widgets/over_drag.dart';
import 'package:kinoko/widgets/pager/pager.dart';
import 'package:my_scrollable_positioned_list/my_scrollable_positioned_list.dart';
import '../images/zoom_image.dart';
import 'dart:math' as math;

const double _DefaultBarHeight = 88;
const double _PageAlignment = 0.1;


class _PageScrollPhysics extends PageScrollPhysics {
  final _VerticalPagerState state;
  _PageScrollPhysics({
    ScrollPhysics parent,
    @required this.state,
  }) : super(parent: parent);

  @override
  _PageScrollPhysics applyTo(ScrollPhysics ancestor) {
    return _PageScrollPhysics(parent: buildParent(ancestor), state: state);
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    var page = state.pageController.page;
    var round = page.round();
    var controller = state.getPageController(round);
    var reverse = false;
    if (offset <= 0 && (page < round ||
        (!reverse && controller.arriveEnd() ||
            reverse && controller.arriveStart()))) {
      return super.applyPhysicsToUserOffset(position, offset);
    } else if (offset > 0 &&
        (page > round || (!reverse && controller.arriveStart() || reverse && controller.arriveEnd()))) {
      return super.applyPhysicsToUserOffset(position, offset);
    } else {
      controller.scrollOffset(offset, false);
      return 0;
    }
  }

  @override
  Simulation createBallisticSimulation(ScrollMetrics position, double velocity) {
    var controller = state.getPageController(state.pageController.page.round());
    if (velocity > 0 && !controller.arriveEnd()) {
      controller.scrollOffset(-velocity / 10, true);
      velocity = 0;
    } else if (velocity < 0 && !controller.arriveStart()) {
      controller.scrollOffset(-velocity / 10, true);
      velocity = 0;
    }
    return super.createBallisticSimulation(position, velocity);
  }
}

class VerticalPager extends Pager {

  final OneFingerCallback onTap;

  VerticalPager({
    Key key,
    NeoCacheManager cacheManager,
    PagerController controller,
    int itemCount,
    PhotoInformation Function(int index) imageUrlProvider,
    this.onTap,
  }) : super(
    key: key,
    cacheManager: cacheManager,
    controller: controller,
    itemCount: itemCount,
    imageUrlProvider: imageUrlProvider,
  );

  @override
  PagerState<Pager> createState() => _VerticalPagerState();
}

class _VerticalPagerState extends PagerState<VerticalPager> {

  _PageScrollPhysics scrollPhysics;
  PageController pageController;
  Map<int, PhotoImageController> _pages = new Map();

  Duration _duration = const Duration(milliseconds: 300);
  bool _listen = true;

  @override
  Widget build(BuildContext context) {
    return OverDrag(
      child: buildScrollable(context),
      up: true,
      down: true,
      onOverDrag: (type) {
        if (type == OverDragType.Left) {
          widget.controller.onOverBound?.call(BoundType.Start);
        } else if (type == OverDragType.Right) {
          widget.controller.onOverBound?.call(BoundType.End);
        }
      },
    );
  }

  Widget buildScrollable(BuildContext context) {
    var media = MediaQuery.of(context);

    AxisDirection axisDirection = AxisDirection.down;
    return Scrollable(
        axisDirection: axisDirection,
        controller: pageController,
        physics: scrollPhysics,
        viewportBuilder: (context, position) {
          return Viewport(
            offset: position,
            axisDirection: axisDirection,
            cacheExtent: 0.1,
            slivers: [
              SliverFillViewport(
                delegate: SliverChildBuilderDelegate((context, index) {
                  PhotoInformation photoInformation = widget.imageUrlProvider(index);
                  PhotoImageController controller = getPageController(index);
                  return Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                        color: Colors.black
                    ),
                    child: Center(
                      child: VerticalImage(
                        imageProvider: NeoImageProvider(
                          uri: Uri.parse(photoInformation.url),
                          cacheManager: widget.cacheManager,
                          headers: photoInformation.headers,
                        ),
                        size: media.size,
                        initFromEnd: index < widget.controller.index,
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
                        controller: controller,
                        onTap: widget.onTap,
                      ),
                    ),
                  );
                },
                  childCount: widget.itemCount,
                ),
              ),
            ],
          );
        }
    );
  }

  @override
  void onNext() {
    if (pageController == null) return;
    int index = pageController.page.round();
    var controller = getPageController(index);
    if (controller.arriveEnd()) {
      if (index >= widget.itemCount - 1) {
        widget.controller.onOverBound(BoundType.End);
      } else {
        pageController.nextPage(duration: _duration, curve: Curves.easeInOutCubic);
      }
    } else {
      controller.next();
    }
  }

  @override
  void onPrev() {
    if (pageController == null) return;
    int index = pageController.page.round();
    var controller = getPageController(index);
    if (controller.arriveStart()) {
      if (index <= 0) {
        widget.controller.onOverBound?.call(BoundType.Start);
      } else {
        pageController.previousPage(duration: _duration, curve: Curves.easeInOutCubic);
      }
    } else {
      controller.prev();
    }
  }

  @override
  void onPage(int page, bool animate) async {
    if (pageController == null) return;
    _listen = false;
    if (animate) {
      await pageController.animateToPage(
        page,
        duration: _duration,
        curve: Curves.easeInOutCubic,
      );
    } else {
      pageController.jumpToPage(page);
    }
    _listen = true;
  }

  PhotoImageController getPageController(int index) {
    if (_pages.containsKey(index)) {
      return _pages[index];
    } else {
      _pages[index] = PhotoImageController();
      return _pages[index];
    }
  }

  @override
  void initState() {
    super.initState();
    scrollPhysics = _PageScrollPhysics(
      state: this,
    );
    _initPageController();
  }

  @override
  void dispose() {
    super.dispose();
    pageController?.dispose();
  }

  @override
  void didUpdateWidget(covariant VerticalPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initPageController();
  }

  void _initPageController() {
    if (pageController == null && widget.itemCount > 0) {
      if (widget.controller.index == -1) {
        widget.controller.index = widget.itemCount - 1;
      }
      pageController = PageController(
        initialPage: widget.controller.index,
      );
      pageController.addListener(() {
        if (_listen) {
          setPage(pageController.page.round());
        }
      });
    }
  }
}