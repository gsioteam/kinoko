
import 'dart:async';

import 'package:flutter/material.dart';


class BetterRefreshIndicatorController {
  BetterRefreshIndicator target;
  bool loading = false;
  Completer<void> completer = Completer<void>();

  Future<void> onRefresh() async {
    if (!loading && target.onExRefresh != null && target.onExRefresh()) {
      loading = true;
    }
    if (loading) return completer.future;
  }

  void startLoading() {
    if (!loading) {
      print("loading start");
      loading = true;
      if (target != null && target.state != null) {
        target.state.show();
      } else {
      }
    } else {
      print("already loading!");
    }
  }

  void stopLoading() {
    if (loading) {
      print("loading stop");
      loading = false;
      completer.complete();
      completer = Completer<void>();
    }
  }

  void initializer() {
    if (loading) {
      if (target != null && target.state != null) {
        target.state.show();
      }
    }
  }
}

class BetterRefreshIndicator extends RefreshIndicator {
  RefreshIndicatorState state;
  BetterRefreshIndicatorController controller;
  bool Function() onExRefresh;

  BetterRefreshIndicator({
    Key key,
    @required Widget child,
    double displacement = 40.0,
    Color color,
    Color backgroundColor,
    ScrollNotificationPredicate notificationPredicate = defaultScrollNotificationPredicate,
    String semanticsLabel,
    String semanticsValue,
    double strokeWidth = 2.0,
    @required BetterRefreshIndicatorController controller,
    bool Function() onRefresh,
  }) : super(
      key: key,
      child: child,
      displacement: displacement,
      color: color,
      backgroundColor: backgroundColor,
      notificationPredicate: notificationPredicate,
      semanticsLabel: semanticsLabel,
      semanticsValue: semanticsValue,
      strokeWidth: strokeWidth,
      onRefresh: controller.onRefresh
  ) {
    this.controller = controller;
    onExRefresh = onRefresh;
    controller.target = this;
  }

  @override
  RefreshIndicatorState createState() {
    state = super.createState();
    _sendInit();
    return state;
  }

  _sendInit() async {
    await Future.delayed(Duration(seconds: 0));
    controller.initializer();
  }
}