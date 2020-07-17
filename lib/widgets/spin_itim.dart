
import 'package:flutter/cupertino.dart';

class SpinItem extends StatefulWidget {
  Widget child;
  bool animated = false;

  _SpinItemState state;

  SpinItem({this.child, this.animated = false});

  @override
  State<StatefulWidget> createState() {
    return state = _SpinItemState();
  }

  void startAnimation() {
    if (state != null) {
      state.setState(() {
        animated = true;
      });
    } else {
      animated = true;
    }
  }

  void stopAnimation() {
    if (state != null) {
      state.setState(() {animated = false;});
    }else
      animated = false;
  }
}

class _SpinItemState extends State<SpinItem> with SingleTickerProviderStateMixin {

  AnimationController animationController;

  @override
  void initState() {
    animationController = AnimationController(
        vsync: this,
        duration: Duration(seconds: 1)
    );
    if (this.widget.animated)
      animationController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      child: this.widget.child,
      builder: (BuildContext context, Widget _widget) {
        return Transform.rotate(
          angle: animationController.value * -6.3,
          child: _widget,
        );
      },
    );
  }
}