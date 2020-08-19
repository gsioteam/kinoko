
import 'package:flutter/cupertino.dart';

class SpinItem extends StatefulWidget {
  Widget child;

  SpinItem({Key key, this.child,}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SpinItemState();
}

class SpinItemState extends State<SpinItem> with SingleTickerProviderStateMixin {

  AnimationController animationController;

  @override
  void initState() {
    animationController = AnimationController(
        vsync: this,
        duration: Duration(seconds: 1)
    );
    super.initState();
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



  void startAnimation() {
    animationController.repeat();
  }


  void stopAnimation() {
    animationController.stop();
    animationController.reset();
  }

  bool get isLoading => animationController.isAnimating;
}