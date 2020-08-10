
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

GlobalKey<_BetterSnackBarListState> _listKey = GlobalKey();
Completer<_BetterSnackBarList> _listCompleter;

class _BetterSnackBarItem extends StatefulWidget {
  String title;
  String subtitle;
  Widget trailing;

  _BetterSnackBarItem({
    this.title,
    this.subtitle,
    this.trailing
  });

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
              Text(widget.title, style: Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),),
              Container(padding: EdgeInsets.only(top: 5),),
              Text(widget.subtitle, style: Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.white),)
            ],
          )
      )
    ];
    if (widget.trailing != null)
      list.add(widget.trailing);
    return Container(
      color: Colors.red,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          children: list,
        ),
      ),
    );
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

class _BetterSnackBarListState extends State<_BetterSnackBarList> {
  List<BetterSnackBar> snackBars = [];
  GlobalKey<AnimatedListState> _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedList(
        shrinkWrap: true,
        key: _key,
        itemBuilder: (context, index, animation) {
          BetterSnackBar bar = snackBars[index];
          return SizeTransition(
            sizeFactor: animation,
            child: bar._getWidget(context),
          );
        },
        reverse: true,
        initialItemCount: snackBars.length,
      )
    );
  }

  void add(BetterSnackBar snackBar) {
    snackBars.insert(0, snackBar);
    _key.currentState.insertItem(0, duration: Duration(milliseconds: 300));
  }

  void remove(BetterSnackBar snackBar) {
    int index = snackBars.indexOf(snackBar);
    if (index >= 0) {
      snackBars.removeAt(index);
      _key.currentState.removeItem(index, (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: snackBar._getWidget(context),
      ), duration: Duration(milliseconds: 300));
    }
  }
}

class BetterSnackBar<T> {
  Widget trailing;
  Widget _widget;
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

  Widget _getWidget(BuildContext context) {
    if (_widget == null) {
      _widget = _BetterSnackBarItem(
        title: title,
        subtitle: subtitle,
        trailing: trailing,
      );
    }
    return _widget;
  }
}