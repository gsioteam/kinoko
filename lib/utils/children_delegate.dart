
import 'package:flutter/widgets.dart';
import 'dart:math' as math;

class ChildrenDelegate extends SliverChildBuilderDelegate {
  void Function(int) onItemShow;

  ChildrenDelegate({
    @required IndexedWidgetBuilder itemBuilder,
    @required IndexedWidgetBuilder separatorBuilder,
    @required int itemCount,
    this.onItemShow,
  }) : super((BuildContext context, int index) {
    final int itemIndex = index ~/ 2;
    Widget widget;
    if (index.isEven) {
      widget = itemBuilder(context, itemIndex);
    } else {
      widget = separatorBuilder(context, itemIndex);
      assert(() {
        if (widget == null) {
          throw FlutterError('separatorBuilder cannot return null.');
        }
        return true;
      }());
    }
    return widget;
  },
    childCount: math.max(0, itemCount * 2 - 1),
  );

  @override
  void didFinishLayout(int firstIndex, int lastIndex) {
    super.didFinishLayout(firstIndex, lastIndex);
    if (this.onItemShow != null) {
      this.onItemShow(lastIndex);
    }
  }
}