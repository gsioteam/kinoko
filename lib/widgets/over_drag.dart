
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as math;
import 'dart:math' as math;

class TransformWidget extends StatefulWidget {

  Widget child;
  Offset translate;

  TransformWidget({
    Key key,
    @required this.child,
    this.translate = Offset.zero,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return TransformWidgetState();
  }

}

class TransformWidgetState extends State<TransformWidget> with SingleTickerProviderStateMixin {

  double position = 0;
  AnimationController controller;


  void translatePosition(double position) {
    controller.stop();
    setState(() {
      this.position = math.max(0, math.min(1, position));
    });
  }

  void receive() {
    controller.reverse(from: position);
  }

  @override
  Widget build(BuildContext context) {
    Offset offset = widget.translate * position;
    return Transform(
      transform: Matrix4.translationValues(offset.dx, offset.dy, 0),
      child: widget.child,
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
    super.dispose();
    controller.stop();
    controller.dispose();
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
  Widget child;
  bool left;
  bool right;
  bool up;
  bool down;
  EdgeInsets iconInsets;
  void Function(OverDragType) onOverDrag;

  OverDrag({
    @required this.child,
    this.left = false,
    this.right = false,
    this.up = false,
    this.down = false,
    this.iconInsets = EdgeInsets.zero,
    this.onOverDrag
  });

  @override
  State<StatefulWidget> createState() => _OverDragState();
}

class _OverDragState extends State<OverDrag> {

  static const double translateSize = 56;

  GlobalKey<TransformWidgetState> _upKey = GlobalKey();
  GlobalKey<TransformWidgetState> _downKey = GlobalKey();
  GlobalKey<TransformWidgetState> _leftKey = GlobalKey();
  GlobalKey<TransformWidgetState> _rightKey = GlobalKey();
  OverDragType type = OverDragType.None;
  double _offset = 0;
  bool _isTouching = false;

  void touchEnd() {
    if (_isTouching) {
      _isTouching = false;
      EdgeInsets padding = MediaQuery.of(context).padding;
      switch (type) {
        case OverDragType.Left: {
          double size = padding.left + translateSize + widget.iconInsets.left;
          if (size - _offset <= 1)
            widget.onOverDrag?.call(type);
          _leftKey.currentState?.receive();
          break;
        }
        case OverDragType.Right: {
          double size = padding.right + translateSize + widget.iconInsets.right;
          if (size - _offset <= 1)
            widget.onOverDrag?.call(type);
          _rightKey.currentState?.receive();
          break;
        }
        case OverDragType.Up: {
          double size = padding.top + translateSize + widget.iconInsets.top;
          if (size - _offset <= 1)
            widget.onOverDrag?.call(type);
          _upKey.currentState?.receive();
          break;
        }
        case OverDragType.Down: {
          double size = padding.bottom + translateSize + widget.iconInsets.bottom;
          if (size - _offset <= 1)
            widget.onOverDrag?.call(type);
          _downKey.currentState?.receive();
          break;
        }
        default: break;
      }

      _offset = 0;
      type = OverDragType.None;
    }
  }

  bool _onNotification(ScrollNotification scrollNotification) {
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
          print("o ${scrollNotification.overscroll} ${type}");
        }
      } else {
        double delta = 0;
        if (scrollNotification is OverscrollNotification) {
          delta = scrollNotification.overscroll;
        } else if (scrollNotification is ScrollUpdateNotification) {
          if (scrollNotification.dragDetails == null) {
            touchEnd();
            return false;
          } else {
            delta = scrollNotification.scrollDelta;
          }
        } else if (scrollNotification is ScrollEndNotification) {
          touchEnd();
          return false;
        } else {
          return false;
        }
        EdgeInsets padding = MediaQuery.of(context).padding;
        switch (type) {
          case OverDragType.Left: {
            double size = padding.left + translateSize + widget.iconInsets.left;
            _offset = math.max(0, math.min(_offset - delta, size));
            _leftKey.currentState?.translatePosition(_offset / size);
            break;
          }
          case OverDragType.Right: {
            double size = padding.right + translateSize + widget.iconInsets.right;
            _offset = math.max(0, math.min(_offset + delta, size));
            _rightKey.currentState?.translatePosition(_offset / size);
            break;
          }
          case OverDragType.Up: {
            double size = padding.top + translateSize + widget.iconInsets.top;
            _offset = math.max(0, math.min(_offset - delta, size));
            _upKey.currentState?.translatePosition(_offset / size);
            break;
          }
          case OverDragType.Down: {
            double size = padding.bottom + translateSize + widget.iconInsets.bottom;
            _offset = math.max(0, math.min(_offset + delta, size));
            _downKey.currentState?.translatePosition(_offset / size);
            break;
          }
          default: break;
        }
      }
    } else {
      if (scrollNotification is ScrollStartNotification && scrollNotification.dragDetails != null) {
        _isTouching = true;
      }
    }
    return false;
  }

  Widget buildArrow(BuildContext context, {
    Key key,
    Offset offset,
    Alignment alignment,
    Icon icon,
    Offset targetOffset
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
      NotificationListener<ScrollNotification>(
        onNotification: _onNotification,
        child: widget.child,
      )
    ];
    EdgeInsets padding = MediaQuery.of(context).padding;
    if (widget.left) {
      list.add(buildArrow(context,
        key: _leftKey,
        alignment: Alignment.centerLeft,
        icon: Icon(Icons.chevron_left),
        offset: Offset(-translateSize, 0),
        targetOffset: Offset(padding.left + translateSize + widget.iconInsets.left, 0),
      ));
    }
    if (widget.right) {
      list.add(buildArrow(context,
        key: _rightKey,
        alignment: Alignment.centerRight,
        icon: Icon(Icons.chevron_right),
        offset: Offset(translateSize, 0),
        targetOffset: Offset(-(padding.right + translateSize + widget.iconInsets.right), 0),
      ));
    }
    if (widget.up) {
      list.add(buildArrow(context,
        key: _upKey,
        alignment: Alignment.topCenter,
        icon: Icon(Icons.keyboard_arrow_up),
        offset: Offset(0, -translateSize),
        targetOffset: Offset(0, padding.top + translateSize + widget.iconInsets.top)
      ));
    }
    if (widget.down) {
      list.add(buildArrow(context,
        key: _downKey,
        alignment: Alignment.bottomCenter,
        icon: Icon(Icons.keyboard_arrow_down),
        offset: Offset(0, translateSize),
        targetOffset: Offset(0, -(padding.bottom + translateSize + widget.iconInsets.bottom))
      ));
    }

    return Stack(
      children: list,
    );
  }

}