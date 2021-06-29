
import 'dart:async';

import 'package:flutter/material.dart';


class BetterRefreshIndicatorController {
  bool loading = false;
  Completer<void> completer = Completer<void>();
  Set<GlobalKey<RefreshIndicatorState>> keys = Set();

  bool Function() onRefresh;
  VoidCallback onLoadMore;

  Future<void> _onRefresh() async {
    if (!loading && onRefresh != null && onRefresh()) {
      loading = true;
    }
    if (loading) return completer.future;
  }

  void startLoading() {
    if (!loading) {
      loading = true;
      for (var key in keys) {
        key.currentState?.show();
      }
    } else {
      print("[E]already loading!");
    }
  }

  void stopLoading() {
    if (loading) {
      loading = false;
      completer.complete();
      completer = Completer<void>();
    }
  }

  void initializer() {
    if (loading) {
      for (var key in keys) {
        key.currentState?.show();
      }
    }
  }

}

class BetterRefreshIndicator extends StatefulWidget {
  final Widget child;
  final double displacement;
  final Color color;
  final Color backgroundColor;
  final ScrollNotificationPredicate notificationPredicate;
  final String semanticsLabel;
  final String semanticsValue;
  final double strokeWidth;
  final BetterRefreshIndicatorController _controller;

  BetterRefreshIndicator({
    Key key,
    @required this.child,
    this.displacement = 40.0,
    this.color,
    this.backgroundColor,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.semanticsLabel,
    this.semanticsValue,
    this.strokeWidth = 2.0,
    @required BetterRefreshIndicatorController controller,
  }) : _controller = controller, super(
    key: key,
  ) {
    assert(_controller != null);
  }

  @override
  State<StatefulWidget> createState() => BetterRefreshIndicatorState();

}

class BetterRefreshIndicatorState extends State<BetterRefreshIndicator> {
  GlobalKey<RefreshIndicatorState> _key = GlobalKey();
  bool cooldown = true;

  @override
  Widget build(BuildContext context) {
    _onInit();
    return NotificationListener<ScrollUpdateNotification>(
      child: RefreshIndicator(
        key: _key,
        child: widget.child,
        displacement: widget.displacement,
        color: widget.color,
        backgroundColor: widget.backgroundColor,
        notificationPredicate: widget.notificationPredicate,
        semanticsLabel: widget.semanticsLabel,
        semanticsValue: widget.semanticsValue,
        strokeWidth: widget.strokeWidth,
        onRefresh: _onRefresh
      ),
      onNotification: (ScrollUpdateNotification notification) {
        if (notification.metrics.maxScrollExtent - notification.metrics.pixels < 20 && cooldown) {
          widget._controller.onLoadMore?.call();
          cooldown = false;
          Future.delayed(Duration(seconds: 2)).then((value) => cooldown = true);
        }
        return false;
      },
    );
  }

  Future<void> _onRefresh() => widget._controller._onRefresh();

  _onInit() async {
    await Future.delayed(Duration(milliseconds: 20));
    widget._controller.initializer();
  }

  @override
  void initState() {
    super.initState();
    widget._controller.keys.add(_key);
  }

  @override
  void dispose() {
    super.dispose();
    widget._controller.keys.remove(_key);
  }
}