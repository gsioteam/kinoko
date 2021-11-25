
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:kinoko/utils/js_extensions.dart';
import 'package:kinoko/utils/plugin/plugin.dart';

import '../configs.dart';

class ExtPage extends StatelessWidget {
  final Plugin plugin;
  final String entry;

  ExtPage({
    Key? key,
    required this.plugin,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    String entry = this.entry;
    if (entry[0] != '/') {
      entry = '/' + entry;
    }
    return DApp(
        entry: entry,
        fileSystems: [plugin.fileSystem],
        classInfo: kiControllerInfo,
        controllerBuilder: (script, state) => KiController(script, plugin)..state = state,
        onInitialize: (script) {
          Configs.instance.setupJS(script, plugin);
          // setupJS(script, plugin);
          //
          // script.global['openVideo'] = script.function((argv) {
          //   OpenVideoNotification(
          //       key: argv[0],
          //       data: jsValueToDart(argv[1]),
          //       plugin: plugin
          //   ).dispatch(context);
          // });
        }
    );
  }
}


class _DisplayRectClipper extends CustomClipper<Rect> {

  Offset center;
  double value;

  _DisplayRectClipper(this.center, this.value);

  @override
  Rect getClip(Size size) {
    double length = (center - Offset(0, size.height)).distance;
    return Rect.fromCircle(
      center: center,
      radius: length * value
    );
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return !(oldClipper is _DisplayRectClipper) || (oldClipper as _DisplayRectClipper).value != value;
  }
}

class ExtPageRoute extends PageRoute {

  final WidgetBuilder builder;
  final Offset center;
  final bool maintainState;
  final Duration duration;

  ExtPageRoute({
    required this.builder,
    required this.center,
    this.maintainState = true,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ClipOval(
          clipper: _DisplayRectClipper(center, animation.value),
          child: child,
        );
      },
      child: builder(context),
    );
  }

  @override
  Duration get transitionDuration => duration;

}