
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

GlobalKey<_BetterSnackBarListState> _listKey = GlobalKey();
Completer<_BetterSnackBarList> _listCompleter;

class _BetterSnackBarItem extends StatefulWidget {
  BetterSnackBar data;

  _BetterSnackBarItem({
    Key key,
    this.data
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BetterSnackBarItemState();

}

class _BetterSnackBarItemState extends State<_BetterSnackBarItem> {

  @override
  Widget build(BuildContext context) {
    List<Widget> list = [
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.data.title, style: Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),),
            Container(padding: EdgeInsets.only(top: 5),),
            Text(widget.data.subtitle, style: Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.white),)
          ],
        )
      )
    ];
    if (widget.data.trailing != null)
      list.add(widget.data.trailing);
    return SizeTransition(
      sizeFactor: widget.data.animation,
      child: Container(
        color: Colors.red,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Row(
            children: list,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }
}

class _BetterSnackBarList extends StatefulWidget {
  static _BetterSnackBarList instance;

  _BetterSnackBarList({
    Key key
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BetterSnackBarListState();
  }

}

class _BetterSnackBarListState extends State<_BetterSnackBarList> with TickerProviderStateMixin {
  List<BetterSnackBar> snackBars = [];
  GlobalKey<AnimatedListState> _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    for (int i = 0, t = snackBars.length; i < t; ++i) {
      BetterSnackBar snackBar = snackBars[i];
      children.add(_BetterSnackBarItem(
        key: ObjectKey(snackBar),
        data: snackBar,
      ));
    }
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      )
    );
  }

  void add(BetterSnackBar snackBar) {
    setState(() {
      snackBars.insert(0, snackBar);
      snackBar.setup(this);
      snackBar.controller.forward();
    });
  }

  void remove(BetterSnackBar snackBar) async {
    await snackBar.controller.reverse();
    snackBar.destroy();
    setState(() {
      snackBars.remove(snackBar);
    });
  }
}

class BetterSnackBar<T> {
  Widget trailing;
  Completer<T> _completer;
  Duration duration;
  Timer _timer;
  String title;
  String subtitle;

  BetterSnackBar({
    this.trailing,
    this.duration,
    this.title,
    this.subtitle
  });

  Future<_BetterSnackBarList> getSnackBarList(BuildContext context) async {
    if (_BetterSnackBarList.instance == null) {
      if (_listCompleter == null) {
        _listCompleter = Completer();
        Overlay.of(context).insert(OverlayEntry(builder: (context) {
          _BetterSnackBarList.instance = _BetterSnackBarList(
            key: _listKey,
          );
          Future.delayed(Duration(milliseconds: 0)).then((value) {
            _listCompleter?.complete(_BetterSnackBarList.instance);
            _listCompleter = null;
          });
          return _BetterSnackBarList.instance;
        }));
      }
      return _listCompleter.future;
    } else {
      return _BetterSnackBarList.instance;
    }
  }

  Future<T> show(BuildContext context) async {
    await getSnackBarList(context);
    _listKey.currentState.add(this);
    _completer = Completer();
    if (duration != null) {
      _timer = Timer(duration, () {
        _listKey.currentState.remove(this);
        _completer.complete();
        _completer = null;
      });
    }
    return _completer.future;
  }

  void dismiss([T value]) {
    if (_completer != null) {
      _listKey.currentState.remove(this);
      _completer.complete(value);
      _completer = null;
      _timer.cancel();
    }
  }

  AnimationController _controller;
  Animation<double> _animation;
  void setup(TickerProvider provider) {
    _controller = AnimationController(vsync: provider, duration: Duration(milliseconds: 300));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  Animation<double> get animation {
    return _animation;
  }

  AnimationController get controller {
    return _controller;
  }

  void destroy() {
    _controller.dispose();
  }
}