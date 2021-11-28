
import 'package:flutter/cupertino.dart';

class SpinItem extends StatefulWidget {
  final Widget? child;

  SpinItem({Key? key, this.child,}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SpinItemState();
}

class SpinItemState extends State<SpinItem> with SingleTickerProviderStateMixin {

  late AnimationController animationController;

  @override
  void initState() {
    animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1)
    );
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      child: this.widget.child,
      builder: (BuildContext context, child) {
        return Transform.rotate(
          angle: animationController.value * -6.3,
          child: child,
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