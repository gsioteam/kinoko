
import 'package:flutter/cupertino.dart';
import 'package:kinoko/utils/neo_cache_manager.dart';
import 'package:kinoko/widgets/images/one_finger_zoom_gesture_recognizer.dart';

class PhotoInformation {
  String? url;
  Map<String, String>? headers;

  PhotoInformation(this.url, [this.headers]);
}

enum BoundType {
  Start,
  End
}

class PagerController {
  Key key = GlobalKey();
  void Function(int)? onPage;
  void Function(BoundType)? onOverBound;
  int _index;
  set index(int v) => _index = v;
  int get index => _index;
  PagerState? state;

  PagerController({
    int index = 0,
    this.onPage,
    this.onOverBound,
  }) : _index = index;


  void dispose() {
    state = null;
  }

  void next() {
    state?.onNext();
  }

  void prev() {
    state?.onPrev();
  }

  void jumpTo(int index) {
    state?.onPage(index, false);
    _index = index;
  }

  void animateTo(int index) {
    state?.onPage(index, true);
    _index = index;
  }

  void _onPage(int page) {
    if (index != page) {
      index = page;
      onPage?.call(page);
    }
  }
}

abstract class Pager extends StatefulWidget {

  final PagerController controller;
  final NeoCacheManager cacheManager;
  final int itemCount;
  final PhotoInformation Function(int index) imageUrlProvider;

  Pager({
    Key? key,
    required this.controller,
    required this.cacheManager,
    required this.itemCount,
    required this.imageUrlProvider,
  }) : super(key: key);

  @override
  PagerState createState();
}

abstract class PagerState<T extends Pager> extends State<T> {

  @override
  void initState() {
    super.initState();
    widget.controller.state = this;
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.controller.state == this)
      widget.controller.state = null;
  }

  void onNext();
  void onPrev();
  void onPage(int page, bool animate);

  void setPage(int page) => widget.controller._onPage(page);
}