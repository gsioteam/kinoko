
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/change_notifier.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:kinoko/utils/neo_cache_manager.dart';
import 'package:kinoko/widgets/pager/pager.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../images/zoom_image.dart';

const double _DefaultBarHeight = 88;
const double _PageAlignment = 0.1;

class VerticalPager extends Pager {

  VerticalPager({
    Key key,
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
  PagerState<Pager> createState() => VerticalPagerState();
}

class VerticalPagerState extends PagerState<VerticalPager> {

  ItemScrollController controller;
  ItemPositionsListener listener;
  bool _listen = true;

  @override
  Widget build(BuildContext context) {
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

        return ZoomImage(
          imageProvider: NeoImageProvider(
            uri: Uri.parse(photoInformation.url),
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
            return Icon(Icons.broken_image);
          },
        );
      },
    );
  }

  @override
  void onNext() {
    _listen = false;
    controller.scrollTo(
      index: widget.controller.index + 1,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      alignment: _PageAlignment,
    ).then((value) => _listen = true);
  }

  @override
  void onPrev() {
    _listen = false;
    controller.scrollTo(
      index: widget.controller.index - 1,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      alignment: _PageAlignment,
    ).then((value) => _listen = true);
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
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _positionUpdate() {
    if (!_listen) return;
    var list = listener.itemPositions.value;
    for (var pos in list) {
      if (pos.itemLeadingEdge < 0.5 && pos.itemTrailingEdge >= 0.5) {
        setPage(pos.index);
        return;
      }
    }
  }
}