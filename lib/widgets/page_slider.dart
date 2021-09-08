
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math' as m;

import 'package:syncfusion_flutter_sliders/sliders.dart';

class PageSlider extends StatefulWidget {

  final int total;
  final int page;
  final FutureOr<void> Function(int) onPage;

  PageSlider({
    Key key,
    this.total,
    this.page,
    this.onPage,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => PageSliderState();
}

class PageSliderState extends State<PageSlider> with SingleTickerProviderStateMixin {
  AnimationController controller;
  int page;

  @override
  Widget build(BuildContext context) {
    if (widget.total > 0) {

      return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    return Visibility(
                        visible: controller.value > 0.05,
                        child: Positioned(
                          child: Opacity(
                            opacity: controller.value,
                            child: child,
                          ),
                          top: 0,
                          bottom: 0,
                          right: 0,
                          width: m.max(constraints.maxWidth * controller.value, 120),
                        )
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(m.min(constraints.maxHeight, constraints.maxWidth) / 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          padding: EdgeInsets.only(
                              left: 10
                          ),
                          constraints: BoxConstraints(),
                          onPressed: dismiss,
                          icon: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            child: Icon(Icons.arrow_right),
                          ),
                        ),
                        Expanded(
                            child: SfSlider(
                              value: page,
                              min: 0,
                              max: widget.total,
                              onChanged: (page) {
                                setState(() {
                                  this.page = (page as double).round();
                                  _pageChanged();
                                });
                              },
                            )
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            right: 10,
                          ),
                          child: Text("${page + 1}/${widget.total}"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
      );
    } else {
      return Visibility(child: Container(), visible: false,);
    }
  }

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      value: 0,
      duration: Duration(milliseconds: 300)
    );
    page = widget.page;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.page != page && !_locked) {
      page = widget.page;
    }
  }

  void show() {
    controller.forward();
  }

  void dismiss() {
    controller.reverse();
  }

  Timer _timer;
  void _pageChanged() {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: 200), () async {
      _locked = true;
      await widget.onPage?.call(page);
      _locked = false;
    });
  }

  bool _locked = false;
}