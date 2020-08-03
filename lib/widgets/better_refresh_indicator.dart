
import 'dart:async';

import 'package:flutter/material.dart';


class BetterRefreshIndicatorController {
  bool loading = false;
  Completer<void> completer = Completer<void>();
  GlobalKey<RefreshIndicatorState> key = GlobalKey();
  bool Function() onRefresh;

  Future<void> _onRefresh() async {
    if (!loading && onRefresh != null && onRefresh()) {
      loading = true;
    }
    if (loading) return completer.future;
  }

  void startLoading() {
    if (!loading) {
      print("[E]loading start");
      loading = true;
      key.currentState?.show();
    } else {
      print("[E]already loading!");
    }
  }

  void stopLoading() {
    if (loading) {
      print("[E]loading stop");
      loading = false;
      completer.complete();
      completer = Completer<void>();
    }
  }

  void initializer() {
    if (loading) {
      key.currentState?.show();
    }
  }
}

class BetterRefreshIndicator extends RefreshIndicator {
  RefreshIndicatorState state;
  BetterRefreshIndicatorController _controller;
  bool Function() onExRefresh;

  BetterRefreshIndicator({
    @required Widget child,
    double displacement = 40.0,
    Color color,
    Color backgroundColor,
    ScrollNotificationPredicate notificationPredicate = defaultScrollNotificationPredicate,
    String semanticsLabel,
    String semanticsValue,
    double strokeWidth = 2.0,
    @required BetterRefreshIndicatorController controller,
  }) : super(
      key: controller.key,
      child: child,
      displacement: displacement,
      color: color,
      backgroundColor: backgroundColor,
      notificationPredicate: notificationPredicate,
      semanticsLabel: semanticsLabel,
      semanticsValue: semanticsValue,
      strokeWidth: strokeWidth,
      onRefresh: controller._onRefresh,
  ) {
    _controller = controller;
  }

  @override
  RefreshIndicatorState createState() {
    _onInit();
    return super.createState();
  }

  _onInit() async {
    await Future.delayed(Duration(milliseconds: 20));
    _controller.initializer();
  }
}