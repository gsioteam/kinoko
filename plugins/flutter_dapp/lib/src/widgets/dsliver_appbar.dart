
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DSliverAppBar extends StatelessWidget {

  final bool floating;
  final bool pinned;
  final double? expandedHeight;
  final Brightness? brightness;
  final Color? background;
  final Color? color;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? child;

  DSliverAppBar({
    Key? key,
    this.floating = false,
    this.pinned = false,
    this.expandedHeight,
    this.background,
    this.color,
    this.brightness,
    this.leading,
    this.actions,
    this.bottom,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: floating,
      pinned: pinned,
      backgroundColor: background,
      expandedHeight: expandedHeight,
      brightness: brightness,
      iconTheme: color == null ? null : IconThemeData(
          color: color
      ),
      actionsIconTheme: color == null ? null : IconThemeData(
          color: color
      ),
      leading: leading,
      bottom: bottom,
      actions: actions,
      flexibleSpace: child,
    );
  }
}