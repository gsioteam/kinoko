
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:kinoko/utils/neo_cache_manager.dart';
import 'package:vector_math/vector_math_64.dart' as m64;
import '../images/photo_image.dart';
import 'pager.dart';

import '../../localizations/localizations.dart';

import 'dart:ui' as ui;
import 'dart:math' as math;


class _PageScrollPhysics extends PageScrollPhysics {
  final _HorizontalPagerState state;
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
    var reverse = state.widget.reverse;
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

class HorizontalPager extends Pager {
  final bool reverse;

  HorizontalPager({
    Key key,
    this.reverse = false,
    NeoCacheManager cacheManager,
    PagerController controller,
    int itemCount,
    PhotoInformation Function(int index) imageUrlProvider,
  }) : super(
    key: key,
    cacheManager: cacheManager,
    controller: controller,
    itemCount: itemCount,
    imageUrlProvider: imageUrlProvider,
  );

  @override
  PagerState createState() => _HorizontalPagerState();
}

class _HorizontalPagerState extends PagerState<HorizontalPager> {

  _PageScrollPhysics scrollPhysics;
  PageController pageController;
  Map<int, PhotoImageController> _pages = new Map();

  Duration _duration = const Duration(milliseconds: 300);
  bool _listen = true;

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context);

    AxisDirection axisDirection = AxisDirection.right;
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
                      child: PhotoImage(
                        imageProvider: NeoImageProvider(
                          uri: Uri.parse(photoInformation.url),
                          cacheManager: widget.cacheManager,
                          headers: photoInformation.headers,
                        ),
                        size: media.size,
                        reverse: widget.reverse,
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
  void didUpdateWidget(covariant HorizontalPager oldWidget) {
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