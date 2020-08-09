
import 'package:flutter/cupertino.dart';

class _BetterSnackBarList extends StatefulWidget {
  static _BetterSnackBarList instance;

  @override
  State<StatefulWidget> createState() {
    return _BetterSnackBarListState();
  }

}

class _BetterSnackBarListState extends State<_BetterSnackBarList> {
  List<BetterSnackBar> snackBars = [];

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      itemBuilder: (context, index, animation) {
        BetterSnackBar bar = snackBars[index];
        return SizeTransition(
          sizeFactor: animation,
          child: bar._getWidget(context),
        );
      },
      reverse: true,
      initialItemCount: snackBars.length,
    );
  }
}

class BetterSnackBar<T> {
  Widget Function(BuildContext) builder;
  Widget _widget;

  BetterSnackBar({
    this.builder
  });

  Future<T> show(BuildContext context) async {
    if (_BetterSnackBarList.instance == null) {
      Overlay.of(context).insert(OverlayEntry(builder: (context) {
        _BetterSnackBarList.instance = _BetterSnackBarList();
        return _BetterSnackBarList.instance;
      }));
    }
  }

  void dismiss([T value]) {

  }

  Widget _getWidget(BuildContext context) {
    if (_widget == null) {
      _widget = builder(context);
    }
    return _widget;
  }
}