

import 'package:flip_widget/flip_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:glib/core/core.dart';
import 'package:kinoko/utils/neo_cache_manager.dart';

import 'dart:math' as math;

import 'pager.dart';


class FlipPage extends StatefulWidget {

  final ImageFetcher imageFetcher;
  final NeoCacheManager? cacheManager;
  final int index;
  final PagerController controller;
  final VoidCallback? onEffectDismissed;

  FlipPage({
    Key? key,
    required this.controller,
    required this.imageFetcher,
    required this.index,
    this.cacheManager,
    this.onEffectDismissed,
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
    Size size = MediaQuery.of(context).size;
    return Container(
      color: Colors.white,
      width: size.width,
      height: size.height,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Image(
          image: NeoImageProvider(
            uri: Uri.parse(photoInformation.url!),
            headers: photoInformation.headers,
            cacheManager: widget.cacheManager,
          ),
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
    if (!_effectLayer) {
      await _flipKey.currentState?.startFlip();
      setState(() {
        _effectLayer = true;
      });
    }
  }

  Future<void> _stopFlip() async {
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

  Offset _startPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return GestureDetector(
      child: Stack(
        children: List<Widget>.generate(_keys.length, (index) {
          int idx = _keys.length - index - 1;
          return FlipPage(
            key: _keys[idx],
            imageFetcher: widget.imageUrlProvider,
            index: idx,
            controller: widget.controller,
            onEffectDismissed: _checkToFree,
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
      onHorizontalDragCancel: () {
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

  void _dragUpdate(Offset position, Size size) {
    Offset off = position - _startPosition;
    int cur = widget.controller.index;
    if (off.dx <= 0) {
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
      }
    }
  }

  void _dragEnd(bool cancel) async {
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
    if (cur >= widget.itemCount - 1) return;
    _keys[cur].currentState?.animate(0, true);
    _updatePosition(cur + 1, cur);
    setPage(cur + 1);
  }

  @override
  void onPage(int page, bool animate) {
    // TODO: implement onPage
  }

  @override
  void onPrev() async {
    int cur = widget.controller.index;
    if (cur <= 0) return;
    _keys[cur - 1].currentState?.animate(1, true);
    _updatePosition(cur - 1, cur);
    setPage(cur - 1);
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
      // _keys[index].currentState?.active = false;
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