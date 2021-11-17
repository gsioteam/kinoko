
import 'package:flutter/material.dart';

class TabItem {
  final String? title;
  final Widget? icon;
  final Widget child;

  TabItem({
    this.title,
    this.icon,
    required this.child,
  });
}

class TabContainer extends StatelessWidget with PreferredSizeWidget {

  final List<Widget> tabs;
  final bool isScrollable;
  final double elevation;

  TabContainer({
    Key? key,
    required this.tabs,
    this.isScrollable = false,
    this.elevation = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).appBarTheme.color,
      child: Center(
        child: TabBar(
          tabs: tabs,
          isScrollable: isScrollable,
        ),
      ),
      elevation: elevation,
    );
  }

  @override
  Size get preferredSize => Size(double.infinity, 36);

}