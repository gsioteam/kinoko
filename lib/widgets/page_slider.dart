
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math' as m;


class PageSlider extends StatefulWidget {

  final int total;
  final int page;
  final FutureOr<void> Function(int) onPage;
  final VoidCallback onAppear;

  PageSlider({
    Key key,
    this.total,
    this.page,
    this.onPage,
    this.onAppear
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
                      color: Theme.of(context).canvasColor,
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
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 0
                            ),
                            child: Slider(
                              value: page.toDouble(),
                              min: 0,
                              max: (widget.total - 1).toDouble(),
                              onChangeEnd: (page) {
                                _pageChanged();
                              },
                              onChanged: (page) {
                                setState(() {
                                  this.page = page.round();
                                });
                              },
                            ),
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
    widget.onAppear?.call();
  }

  void dismiss() {
    controller.reverse();
  }

  void _pageChanged() async {
    _locked = true;
    await widget.onPage?.call(page);
    _locked = false;
  }

  bool _locked = false;
}