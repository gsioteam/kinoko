
import 'package:flutter/material.dart';

import '../dwidget.dart';

enum DButtonType {
  elevated,
  text,
  icon,
  material,
}

class DButton extends StatelessWidget {

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final DButtonType type;
  final Size? minimumSize;
  final MaterialTapTargetSize? tapTargetSize;
  final EdgeInsets? padding;
  final Color? color;

  DButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.type = DButtonType.elevated,
    this.minimumSize,
    this.tapTargetSize,
    this.padding,
    this.color,
  }) : super(key: key);



  @override
  Widget build(BuildContext context) {
    switch (type) {
      case DButtonType.elevated: {
        return ElevatedButton(
          onPressed: onPressed,
          onLongPress: onLongPress,
          child: child,
          style: ElevatedButton.styleFrom(
            tapTargetSize: tapTargetSize,
            minimumSize: minimumSize,
            padding: padding,
            primary: color,
          ),
        );
      }
      case DButtonType.icon: {
        return IconButton(
          icon: child,
          onPressed: onPressed,
          constraints: BoxConstraints(
            minWidth: minimumSize?.width ?? 0,
            minHeight: minimumSize?.height ?? 0,
          ),
          padding: padding ?? const EdgeInsets.all(8.0),
          color: color,
        );
      }
      case DButtonType.material: {
        return MaterialButton(
          child: child,
          onPressed: onPressed,
          onLongPress: onLongPress,
          minWidth: minimumSize?.width ?? 0,
          materialTapTargetSize: tapTargetSize,
          padding: padding,
          color: color,
        );
      }
      case DButtonType.text: {
        return TextButton(
          onPressed: onPressed,
          onLongPress: onLongPress,
          child: child,
          style: TextButton.styleFrom(
            tapTargetSize: tapTargetSize,
            minimumSize: minimumSize,
            padding: padding,
            primary: color,
          ),
        );
      }
    }
  }
}
