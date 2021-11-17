
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class View extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final Widget? child;
  final bool animate;
  final Duration duration;
  final Clip clip;
  final Border? border;
  final BorderRadius? radius;
  final Gradient? gradient;
  final EdgeInsets? padding;

  View({
    Key? key,
    this.width,
    this.height,
    this.color,
    this.child,
    this.animate = false,
    this.duration = const Duration(milliseconds: 300),
    this.clip = Clip.none,
    this.border,
    this.radius,
    this.gradient,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    BoxDecoration? _decoration;
    if (color != null ||
        border != null ||
        radius != null ||
        gradient != null) {
      _decoration = BoxDecoration(
        color: color,
        border: border,
        borderRadius: radius,
        gradient: gradient,
      );
    }

    if (animate) {
      return AnimatedContainer(
        duration: duration,
        width: width,
        height: height,
        clipBehavior: clip,
        child: child,
        padding: padding,
        decoration: _decoration,
      );
    } else {
      return Container(
        width: width,
        height: height,
        clipBehavior: clip,
        child: child,
        padding: padding,
        decoration: _decoration,
      );
    }
  }
}