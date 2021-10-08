
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const double _pointSize = 12;

class HintPoint extends StatefulWidget {

  final ValueNotifier<bool> controller;

  HintPoint({
    Key key,
    this.controller,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HintPointState();

}

class _HintPointState extends State<HintPoint> {
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget.controller.value,
      child: Container(
        width: _pointSize,
        height: _pointSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_pointSize/2),
          color: Colors.red,
          border: Border.all(
            color: Theme.of(context).colorScheme.surface,
            width: 2,
          )
        ),
      )
    );
  }

  void _update() {
    setState(() {
    });
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_update);
  }
}