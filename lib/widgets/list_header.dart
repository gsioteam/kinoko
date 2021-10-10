
import 'package:flutter/cupertino.dart';

class ListHeader extends StatelessWidget {

  final Widget child;

  ListHeader({
    Key key,
    this.child
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 18,
      ),
      child: child,
    );
  }
}