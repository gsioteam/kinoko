
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as math;
import 'dart:math' as math;

class OverDragUpdateNotification extends Notification {
  final Offset offset;

  OverDragUpdateNotification(this.offset);
}

class TransformWidget extends StatefulWidget {

  final Widget child;
  final Offset translate;

  TransformWidget({
    Key? key,
    required this.child,
    this.translate = Offset.zero,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return TransformWidgetState();
  }

}

class TransformWidgetState extends State<TransformWidget> with SingleTickerProviderStateMixin {

  double position = 0;
  late AnimationController controller;
  bool active = false;

  void translatePosition(double position, bool active) {
    controller.stop();
    setState(() {
      this.position = math.max(0, math.min(1, position));
      this.active = active;
    });
  }

  void receive() {
    controller.reverse(from: position);
  }

  @override
  Widget build(BuildContext context) {
    Offset offset = widget.translate * position;
    var theme = Theme.of(context);
    return Transform(
      transform: Matrix4.translationValues(offset.dx, offset.dy, 0),
      child: IconTheme(
          data: IconThemeData(
            color: active ? theme.primaryColor : theme.disabledColor,
          ),
          child: widget.child
      ),
    );
  }

  onValueChanged() {
    setState(() {
      position = math.max(0, math.min(1, controller.value));
    });
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    controller.addListener(onValueChanged);
  }

  @override
  void dispose() {
    controller.stop();
    controller.dispose();
    super.dispose();
  }
}

enum OverDragType {
  None,
  Up,
  Down,
  Left,
  Right
}

class OverDrag extends StatefulWidget {
  final Widget child;
  final bool left;
  final bool right;
  final bool up;
  final bool down;
  final EdgeInsets iconInsets;
  final void Function(OverDragType)? onOverDrag;

  OverDrag({
    Key? key,
    required this.child,
    this.left = false,
    this.right = false,
    this.up = false,
    this.down = false,
    this.iconInsets = EdgeInsets.zero,
    this.onOverDrag
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => OverDragState();
}

class OverDragState extends State<OverDrag> {

  static const double translateSize = 56;
  static const double redundancy = 10;

  GlobalKey<TransformWidgetState> _upKey = GlobalKey();
  GlobalKey<TransformWidgetState> _downKey = GlobalKey();
  GlobalKey<TransformWidgetState> _leftKey = GlobalKey();
  GlobalKey<TransformWidgetState> _rightKey = GlobalKey();
  OverDragType type = OverDragType.None;
  double _offset = 0;
  bool _isTouching = false;

  bool _isActive() {
    EdgeInsets padding = MediaQuery.of(context).padding;
    switch (type) {
      case OverDragType.Left: {
        double size = padding.left + translateSize + widget.iconInsets.left;
        return size - _offset <= redundancy;
      }
      case OverDragType.Right: {
        double size = padding.right + translateSize + widget.iconInsets.right;
        return size - _offset <= redundancy;
      }
      case OverDragType.Up: {
        double size = padding.top + translateSize + widget.iconInsets.top;
        return size - _offset <= redundancy;
      }
      case OverDragType.Down: {
        double size = padding.bottom + translateSize + widget.iconInsets.bottom;
        return size - _offset <= redundancy;
      }
      default: break;
    }
    return false;
  }

  bool touchEnd() {
    if (_isTouching) {
      _isTouching = false;
      EdgeInsets padding = MediaQuery.of(context).padding;
      switch (type) {
        case OverDragType.Left: {
          double size = padding.left + translateSize + widget.iconInsets.left;
          if (size - _offset <= redundancy)
            widget.onOverDrag?.call(type);
          _leftKey.currentState?.receive();
          break;
        }
        case OverDragType.Right: {
          double size = padding.right + translateSize + widget.iconInsets.right;
          if (size - _offset <= redundancy)
            widget.onOverDrag?.call(type);
          _rightKey.currentState?.receive();
          break;
        }
        case OverDragType.Up: {
          double size = padding.top + translateSize + widget.iconInsets.top;
          if (size - _offset <= redundancy)
            widget.onOverDrag?.call(type);
          _upKey.currentState?.receive();
          break;
        }
        case OverDragType.Down: {
          double size = padding.bottom + translateSize + widget.iconInsets.bottom;
          if (size - _offset <= redundancy)
            widget.onOverDrag?.call(type);
          _downKey.currentState?.receive();
          break;
        }
        default: break;
      }

      _offset = 0;
      type = OverDragType.None;
      return true;
    }
    return false;
  }

  bool _onNotification(Notification scrollNotification) {
    if (_isTouching) {

      if (type == OverDragType.None) {
        if (scrollNotification is OverscrollNotification) {
          if (scrollNotification.metrics.axis == Axis.horizontal) {
            if (scrollNotification.overscroll > 0) {
              type = OverDragType.Right;
            } else if (scrollNotification.overscroll < 0) {
              type = OverDragType.Left;
            }
          } else {
            if (scrollNotification.overscroll > 0) {
              type = OverDragType.Down;
            } else if (scrollNotification.overscroll < 0) {
              type = OverDragType.Up;
            }
          }
        }
      } else {
        double delta = 0;
        if (scrollNotification is OverscrollNotification) {
          delta = scrollNotification.overscroll;
        } else if (scrollNotification is ScrollUpdateNotification) {
          if (scrollNotification.dragDetails == null) {
            return touchEnd();
          } else {
            delta = scrollNotification.scrollDelta!;
          }
        } else if (scrollNotification is ScrollEndNotification) {
          return touchEnd();
        } else if (scrollNotification is OverDragUpdateNotification) {
          switch (type) {
            case OverDragType.Up:
            case OverDragType.Down:
              delta = -scrollNotification.offset.dy;
              break;
            case OverDragType.Left:
            case OverDragType.Right:
              delta = -scrollNotification.offset.dx;
              break;
            default: {}
          }
        } else {
          return false;
        }
        _dragUpdate(delta);
      }
    } else {
      if (scrollNotification is ScrollStartNotification && scrollNotification.dragDetails != null) {
        _isTouching = true;
      }
    }
    return false;
  }

  Widget buildArrow(BuildContext context, {
    Key? key,
    required Offset offset,
    required Alignment alignment,
    Icon? icon,
    required Offset targetOffset
  }) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: TransformWidget(
            key: key,
            translate: targetOffset,
            child: Transform(
              transform: Matrix4.translationValues(offset.dx, offset.dy, 0),
              child: Container(
                child: icon,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 3,
                      offset: Offset(1, 1)
                    )
                  ]
                ),
                width: 36,
                height: 36,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> list = [
      NotificationListener(
        onNotification: _onNotification,
        child: widget.child,
      )
    ];
    var theme = Theme.of(context);
    EdgeInsets padding = MediaQuery.of(context).padding;
    if (widget.left) {
      list.add(buildArrow(context,
        key: _leftKey,
        alignment: Alignment.centerLeft,
        icon: Icon(
          Icons.chevron_left,
        ),
        offset: Offset(-translateSize, 0),
        targetOffset: Offset(padding.left + translateSize + widget.iconInsets.left, 0),
      ));
    }
    if (widget.right) {
      list.add(buildArrow(context,
        key: _rightKey,
        alignment: Alignment.centerRight,
        icon: Icon(
          Icons.chevron_right,
        ),
        offset: Offset(translateSize, 0),
        targetOffset: Offset(-(padding.right + translateSize + widget.iconInsets.right), 0),
      ));
    }
    if (widget.up) {
      print(_isActive());
      list.add(buildArrow(context,
        key: _upKey,
        alignment: Alignment.topCenter,
        icon: Icon(
          Icons.keyboard_arrow_up,
        ),
        offset: Offset(0, -translateSize),
        targetOffset: Offset(0, padding.top + translateSize + widget.iconInsets.top)
      ));
    }
    if (widget.down) {
      list.add(buildArrow(context,
        key: _downKey,
        alignment: Alignment.bottomCenter,
        icon: Icon(
          Icons.keyboard_arrow_down,
        ),
        offset: Offset(0, translateSize),
        targetOffset: Offset(0, -(padding.bottom + translateSize + widget.iconInsets.bottom))
      ));
    }

    return Stack(
      children: list,
    );
  }

  void _dragUpdate(double delta) {
    EdgeInsets padding = MediaQuery.of(context).padding;
    switch (type) {
      case OverDragType.Left: {
        double size = padding.left + translateSize + widget.iconInsets.left;
        _offset = math.max(0, math.min(_offset - delta, size));
        _leftKey.currentState?.translatePosition(_offset / size, size - _offset <= redundancy);
        break;
      }
      case OverDragType.Right: {
        double size = padding.right + translateSize + widget.iconInsets.right;
        _offset = math.max(0, math.min(_offset + delta, size));
        _rightKey.currentState?.translatePosition(_offset / size, size - _offset <= redundancy);
        break;
      }
      case OverDragType.Up: {
        double size = padding.top + translateSize + widget.iconInsets.top;
        _offset = math.max(0, math.min(_offset - delta, size));
        _upKey.currentState?.translatePosition(_offset / size, size - _offset <= redundancy);
        break;
      }
      case OverDragType.Down: {
        double size = padding.bottom + translateSize + widget.iconInsets.bottom;
        _offset = math.max(0, math.min(_offset + delta, size));
        _downKey.currentState?.translatePosition(_offset / size, size - _offset <= redundancy);
        break;
      }
      default: break;
    }
  }

  void correction(Offset offset) {
    switch (type) {
      case OverDragType.Left:
      case OverDragType.Right: {
        _dragUpdate(offset.dx);
        break;
      }
      case OverDragType.Up:
      case OverDragType.Down: {
        _dragUpdate(offset.dy);
        break;
      }
      default:
    }
  }

}