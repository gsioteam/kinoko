

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

const double _IndicatorSize = 38;

class DRefresh extends StatefulWidget {
  final bool loading;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoadMore;
  final Widget child;
  final double refreshInset;

  DRefresh({
    Key? key,
    required this.child,
    this.loading = false,
    this.onRefresh,
    this.onLoadMore,
    this.refreshInset = 36,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DRefreshState();
}

class _DRefreshState extends State<DRefresh> with TickerProviderStateMixin {

  late AnimationController refreshController;

  double refreshProgress = 0;
  bool waitForRefresh = false;
  bool _dismiss = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          child: widget.child,
          onNotification: _onNotification,
        ),
        Align(
          alignment: Alignment.topCenter,
          child: AnimatedBuilder(
            animation: refreshController,
            builder: (context, child) {
              refreshProgress = ((refreshController.value)/(refreshController.upperBound - 8)).clamp(0, 1);
              return Transform(
                alignment: Alignment.center,
                transform: _dismiss ?
                (Matrix4.translation(Vector3(0, widget.refreshInset, 0))
                  ..scale(refreshProgress)):
                Matrix4.translation(Vector3(0, refreshController.value, 0)),
                child: RefreshProgressIndicator(
                  backgroundColor: Theme.of(context).canvasColor,
                  value: _isRefresh() ? null : refreshProgress,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    refreshController = AnimationController(
      vsync: this,
      lowerBound: -_IndicatorSize - 10,
      upperBound: widget.refreshInset,
      value: -_IndicatorSize - 10,
      duration: Duration(milliseconds: 300),
    );

    if (widget.loading) {
      Future.delayed(Duration(milliseconds: 30)).then((value) => refreshController.forward());
    }
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  bool _onNotification(ScrollNotification notification) {
    if (!_isRefresh()) {
      if (notification is OverscrollNotification && widget.onRefresh != null) {
        _dismiss = false;
        refreshController.value -= notification.overscroll;
      } else if (notification is ScrollUpdateNotification) {
        if (notification.scrollDelta != null && notification.metrics.pixels < 0 && widget.onRefresh != null) {
          if (notification.dragDetails != null) {
            _dismiss = false;
            refreshController.value -= notification.scrollDelta!;
          } else {
            if (refreshProgress >= 1) {
              _dismiss = false;
              waitForRefresh = true;
              Future.delayed(Duration(milliseconds: 300)).then((value) {
                if (!widget.loading) {
                  _dismiss = true;
                  refreshController.reverse().then((value) {
                    setState(() {
                      waitForRefresh = false;
                    });
                  });
                }
              });
              refreshController.forward();
              widget.onRefresh?.call();
            }
          }
        } else if (notification.scrollDelta != null && notification.scrollDelta! > 0 && widget.onRefresh != null) {
          _dismiss = false;
          refreshController.value -= notification.scrollDelta!;
        } else if (notification.metrics.maxScrollExtent - notification.metrics.pixels < 20 && widget.onLoadMore != null) {
          _dismiss = false;
          waitForRefresh = true;
          widget.onLoadMore?.call();
          refreshController.forward();
          Future.delayed(Duration(milliseconds: 300)).then((value) {
            if (!widget.loading) {
              _dismiss = true;
              refreshController.reverse().then((value) {
                setState(() {
                  waitForRefresh = false;
                });
              });
            }
          });
        }
      } else if (notification is ScrollEndNotification) {
        if (refreshProgress >= 1) {
          _dismiss = false;
          waitForRefresh = true;
          Future.delayed(Duration(milliseconds: 300)).then((value) {
            if (!widget.loading) {
              _dismiss = true;
              refreshController.reverse().then((value) {
                setState(() {
                  waitForRefresh = false;
                });
              });
            }
          });
          refreshController.forward();
          widget.onRefresh?.call();
        } else {
          _dismiss = false;
          refreshController.reverse();
        }
      }
    }
    return false;
  }

  bool _isRefresh() {
    return waitForRefresh || widget.loading;
  }

  @override
  void didUpdateWidget(covariant DRefresh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading != oldWidget.loading) {
      if (!widget.loading) {
        waitForRefresh = false;
        _dismiss = true;
        refreshController.reverse();
      } else {
        if (!waitForRefresh) {
          _dismiss = false;
          refreshController.forward();
        }
      }
    }
  }
}