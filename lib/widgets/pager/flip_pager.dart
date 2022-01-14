

import 'package:flip_widget/flip_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:glib/core/core.dart';
import 'package:kinoko/utils/neo_cache_manager.dart';
import 'package:kinoko/widgets/images/one_finger_zoom_gesture_recognizer.dart';
import 'package:kinoko/widgets/images/contain_image.dart';
import 'package:kinoko/widgets/images/photo_image.dart';
import 'package:kinoko/widgets/over_drag.dart';

import 'dart:math' as math;

import 'pager.dart';


class FlipPage extends StatefulWidget {

  final ImageFetcher imageFetcher;
  final NeoCacheManager? cacheManager;
  final int index;
  final PagerController controller;
  final VoidCallback? onEffectDismissed;
  final OneFingerCallback? onTap;

  FlipPage({
    Key? key,
    required this.controller,
    required this.imageFetcher,
    required this.index,
    this.cacheManager,
    this.onEffectDismissed,
    this.onTap,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FlipPageState();
}

const SizedBox _empty = const SizedBox.shrink();

const double _maxSize = 1.0;

class _FlipPageState extends State<FlipPage> with SingleTickerProviderStateMixin {

  GlobalKey<FlipWidgetState> _flipKey = GlobalKey();
  bool _flipping = false;

  bool _hidden = true;
  bool _active = false;
  bool _effectLayer = false;

  bool get effectLayer => _effectLayer;

  late AnimationController _animationController;
  PhotoImageController controller = PhotoImageController();


  bool _disposed = false;

  @override
  Widget build(BuildContext context) {
    if (_active) {
      Size size = MediaQuery.of(context).size;
      return Transform.translate(
        offset: Offset(_hidden && !_effectLayer ? -size.width:0, 0),
        child: FlipWidget(
          key: _flipKey,
          child: buildImage(context),
        ),
      );
    } else {
      return _empty;
    }
  }

  Widget buildImage(BuildContext context) {
    PhotoInformation photoInformation = widget.imageFetcher(widget.index);
    var media = MediaQuery.of(context);
    return Container(
      color: Colors.white,
      width: media.size.width,
      height: media.size.height,
      child: FittedBox(
        fit: BoxFit.contain,
        child: photoInformation.url == null ?
        SpinKitRing(
          lineWidth: 4,
          size: 36,
          color: Colors.black87,
        ) : ContainImage(
          imageProvider: NeoImageProvider(
            uri: Uri.parse(photoInformation.url!),
            cacheManager: widget.cacheManager,
            headers: photoInformation.headers,
          ),
          size: media.size,
          loadingWidget: (context) {
            return SpinKitRing(
              lineWidth: 4,
              size: 36,
              color: Colors.black87,
            );
          },
          errorWidget: (context) {
            return Icon(
              Icons.broken_image,
              color: Colors.black87,
            );
          },
          onTap: widget.onTap,
          controller: controller,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _animationController.addListener(_animateUpdate);

    int cur = widget.controller.index;
    if (widget.index >= cur)
      _hidden = false;
    _active = widget.index - cur >= - 1 && widget.index - cur <= 1;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
    _disposed = true;
  }

  set active(bool v) {
    if (_active != v) {
      _active = v;
      if (!_animationController.isAnimating) {
        _hidden = widget.index < widget.controller.index;
        setState(() {});
      }
    }
  }

  Future<void> _startFlip() async {
    if (_disposed) return;
    if (!_effectLayer) {
      await _flipKey.currentState?.startFlip();
      setState(() {
        _effectLayer = true;
      });
    }
  }

  Future<void> _stopFlip() async {
    if (_disposed) return;
    _flipping = false;
    if (_effectLayer) {
      _effectLayer = false;
      widget.onEffectDismissed?.call();
      setState(() { });
      await _flipKey.currentState?.stopFlip();
    }
  }

  double _currentPercent = -99;
  double _currentTilt = 3;
  void flip(double p, double t) async {
    if (_disposed) return;
    _animationController.stop(canceled: true);
    _currentPercent = p;
    _currentTilt = t;
    if (!_flipping) {
      _flipping = true;
      await _startFlip();
    }
    await _flipKey.currentState?.flip(p, t);
  }

  double _fromPercent = 0;
  double _fromTilt = 1;
  double _toPercent = 0;
  double _toTilt = 1;
  Future<void> animate(double to, bool stop) async {
    _animationController.stop(canceled: true);
    if (_currentPercent == -99) {
      _currentPercent = _hidden ? _maxSize : 0;
      _currentTilt = _hidden ? 9 : 3;
    }
    if (!_flipping) {
      await _startFlip();
    }
    _fromPercent = _currentPercent;
    _fromTilt = _currentTilt;
    _toPercent = (1 - to) * _maxSize;
    _toTilt = (1 - to) * 6 + 3;
    _animationController.forward(from: 0).whenComplete(() {
      _hidden = to == 0;
      if (stop) {
        _stopFlip();
      }
    });
  }

  void _animateUpdate() {
    double value = _animationController.value; //Curves.easeOutCubic.transform(_animationController.value);
    double percent = _fromPercent * (1 - value) + _toPercent * value;
    double tilt = _fromTilt * (1 - value) + _toTilt * value;
    _currentPercent = percent;
    _currentTilt = tilt;
    _flipKey.currentState?.flip(percent, tilt);
  }

  bool get hidden => _hidden;
  set hidden(bool hidden) {
    if (_hidden != hidden) {
      _hidden = hidden;
      if (!effectLayer) {
        setState(() {});
      }
    }
  }
}

class FlipPager extends Pager {
  final void Function(PointerEvent event)? onTap;

  FlipPager({
    Key? key,
    required NeoCacheManager cacheManager,
    required PagerController controller,
    required int itemCount,
    required ImageFetcher imageUrlProvider,
    this.onTap,
  }) : super(
    key: key,
    cacheManager: cacheManager,
    controller: controller,
    itemCount: itemCount,
    imageUrlProvider: imageUrlProvider,
  );

  @override
  PagerState<Pager> createState() => FlipPagerState();
}

class FlipPagerState extends PagerState<FlipPager> {
  List<GlobalKey<_FlipPageState>> _keys = [];
  GlobalKey<OverDragState> _overDragKey = GlobalKey();

  Offset _startPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return OverDrag(
      key: _overDragKey,
      left: true,
      right: true,
      child: GestureDetector(
        child: Stack(
          children: List<Widget>.generate(_keys.length, (index) {
            int idx = _keys.length - index - 1;
            return FlipPage(
              key: _keys[idx],
              imageFetcher: widget.imageUrlProvider,
              index: idx,
              controller: widget.controller,
              onEffectDismissed: _checkToFree,
              onTap: widget.onTap,
            );
          }),
        ),
        onHorizontalDragStart: (details) {
          _dragStart(details.globalPosition);
        },
        onHorizontalDragUpdate: (details) {
          _dragUpdate(details.globalPosition, size);
        },
        onHorizontalDragEnd: (details) {
          _dragEnd(false);
        },
      ),
      onOverDrag: (type) {
        if (type == OverDragType.Left || type == OverDragType.Up) {
          widget.controller.onOverBound?.call(BoundType.Start);
        } else if (type == OverDragType.Right || type == OverDragType.Down) {
          widget.controller.onOverBound?.call(BoundType.End);
        }
      },
    );
  }

  int _activeIndex = 0;
  double _lastPercent = 0;
  double _lastTilt = 1;

  void _dragStart(Offset position) {
    _startPosition = position;
    _activeIndex = -1;
  }

  double _oldPosition = 0;
  void _dragUpdate(Offset position, Size size) {
    Offset off = position - _startPosition;
    int cur = widget.controller.index;
    if (off.dx <= 0) {
      if (cur < _keys.length - 1) {
        double percent = math.max(0, -off.dx / size.width);
        percent *= 1.2;
        double tilt = math.max(0.3, math.min(9.0, 3.0 + off.dy / 50));
        percent = percent - math.max(0, percent / 2 * (1-1/tilt));

        _keys[cur].currentState?.flip(percent, tilt);
        if (_activeIndex != cur && _activeIndex != -1) {
          _keys[_activeIndex].currentState?._stopFlip();
        }
        _activeIndex = cur;
        _lastPercent = percent;
        _lastTilt = tilt;
      } else {
        _overDragKey.currentState?.onOverDrag(OverDragType.Right, _oldPosition - off.dx);
        _oldPosition = off.dx;
      }
    } else {
      if (cur > 0) {
        double percent = 1 - math.min(1, off.dx / size.width);
        percent *= 1.2;
        double tilt = math.max(0.3, math.min(8.0, 3.0 + off.dy / 50));
        percent = percent - math.max(0, percent / 2 * (1-1/tilt));

        _keys[cur-1].currentState?.flip(percent, tilt);
        if (_activeIndex != cur-1 && _activeIndex != -1) {
          _keys[_activeIndex].currentState?._stopFlip();
        }
        _activeIndex = cur-1;
        _lastPercent = percent;
        _lastTilt = tilt;
      } else {
        if (_activeIndex != cur && _activeIndex != -1) {
          _keys[_activeIndex].currentState?._stopFlip();
        }
        _activeIndex = cur;
        _lastPercent = 0;
        _lastTilt = 1;
        _overDragKey.currentState?.onOverDrag(OverDragType.Left, _oldPosition-off.dx);
        _oldPosition = off.dx;
      }
    }
  }

  void _dragEnd(bool cancel) async {
    _overDragKey.currentState?.touchEnd();
    if (_activeIndex == -1) return;
    double to = 0;
    int _dash = 0;
    if (cancel) {
      if (_activeIndex < widget.controller.index) {
        to = 0;
      } else {
        to = 1;
      }
    } else {
      if (_activeIndex < widget.controller.index) {
        if (_lastPercent < 0.7) {
          to = 1;
          _dash = -1;
        } else {
          to = 0;
        }
      } else {
        if (_lastPercent > 0.3) {
          to = 0;
          _dash = 1;
        } else {
          to = 1;
        }
      }
    }
    if (_dash != 0) {
      int _oldIndex = widget.controller.index;
      _updatePosition(_oldIndex + _dash, _oldIndex);
      setPage(_oldIndex + _dash);
    }
    await _keys[_activeIndex].currentState?.animate(to, true);
  }

  @override
  void onNext() async {
    int cur = widget.controller.index;
    if (cur >= widget.itemCount - 1) {
      widget.controller.onOverBound?.call(BoundType.End);
    } else {
      _keys[cur].currentState?.animate(0, true);
      _updatePosition(cur + 1, cur);
      setPage(cur + 1);
    }
  }

  @override
  void onPrev() async {
    int cur = widget.controller.index;
    if (cur <= 0) {
      widget.controller.onOverBound?.call(BoundType.Start);
    } else {
      _keys[cur - 1].currentState?.animate(1, true);
      _updatePosition(cur - 1, cur);
      setPage(cur - 1);
    }
  }

  @override
  void onPage(int page, bool animate) {
    int cur = widget.controller.index;
    if (page == cur) return;
    if (animate) {
      List<int> animPages = [];
      if (cur < page) {
        for (int i = cur; i < page && i < cur + 5; ++i) {
          animPages.add(i);
        }
      } else {
        for (int i = cur - 1; i > page + 1 && i > cur - 3; --i) {
          animPages.add(i);
        }
        animPages.add(page + 1);
        animPages.add(page);
      }
      _animateTo(animPages, cur, page);
      setPage(page);
      _updatePosition(page);
    } else {
      setPage(page);
      _updatePosition(page, cur);
      if (page - 1 >= 0) _keys[page - 1].currentState?.hidden = true;
      _keys[page].currentState?.hidden = false;
      if (page + 1 < _keys.length) _keys[page + 1].currentState?.hidden = false;
      _checkToFree();
    }
  }

  void _animateTo(List<int> pages, int from, int to) async {
    int cur = from;
    for (int idx in pages) {
      var state = _keys[idx].currentState;
      state?.active = true;
      if (idx < cur) {
        state?.hidden = true;
      }
    }
    await Future.delayed(Duration(milliseconds: 100));
    for (int idx in pages) {
      if (cur < to) {
        _keys[idx].currentState?.animate(0, true);
      } else {
        _keys[idx].currentState?.animate(1, true);
      }
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  @override
  void initState() {
    super.initState();

    _keys = List.generate(widget.itemCount, (index) {
      return GlobalKey();
    });

    _initPageController();
  }

  @override
  void didUpdateWidget(covariant FlipPager oldWidget) {
    super.didUpdateWidget(oldWidget);

    while (_keys.length < widget.itemCount) {
      _keys.add(GlobalKey());
    }
    while (_keys.length > widget.itemCount) {
      _keys.removeLast();
    }
  }

  void _initPageController() {
    if (widget.itemCount > 0) {
      if (widget.controller.index == -1) {
        widget.controller.index = widget.itemCount - 1;
        _updatePosition(widget.controller.index);
      }
    }
  }

  void _updatePosition(int newIndex, [int? oldIndex]) {
    List<int> disappears = [];
    void addDisappear(int index) {
      if (index >= 0 && index < _keys.length) disappears.add(index);
    }
    List<int> appears = [];
    void addAppear(int index) {
      if (index >= 0 && index < _keys.length) {
        if (disappears.contains(index)) disappears.remove(index);
        appears.add(index);
      }
    }
    if (oldIndex != null) {
      addDisappear(oldIndex - 1);
      addDisappear(oldIndex);
      addDisappear(oldIndex + 1);
    }
    addAppear(newIndex - 1);
    addAppear(newIndex);
    addAppear(newIndex + 1);

    for (int index in disappears) {
      if (index < newIndex) {
        _keys[index].currentState?.hidden = true;
      }
    }
    for (int index in appears) {
      _keys[index].currentState?.active = true;
    }
  }

  void _checkToFree() {
    for (var key in _keys) {
      if (key.currentState?.effectLayer == true) {
        return;
      }
    }
    int cur = widget.controller.index;
    for (int i = 0, t = _keys.length; i < t; ++i) {
      if (i < cur - 1 || i > cur + 1) {
        _keys[i].currentState?.active = false;
      }
    }
  }
}