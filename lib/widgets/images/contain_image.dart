
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'one_finger_zoom_gesture_recognizer.dart';
import 'photo_image.dart';
import 'dart:ui' as ui;

class ContainImage extends PhotoImage {
  ContainImage({
    Key? key,
    required ImageProvider imageProvider,
    required Size size,
    WidgetBuilder? loadingWidget,
    WidgetBuilder? errorWidget,
    bool initFromEnd = false,
    PhotoImageController? controller,
    OneFingerCallback? onTap,
    Color backgroundColor = Colors.black,
  }) : super(
    key: key,
    imageProvider: imageProvider,
    size: size,
    loadingWidget: loadingWidget,
    errorWidget: errorWidget,
    initFromEnd: initFromEnd,
    controller: controller,
    reverse: false,
    onTap: onTap,
    backgroundColor: backgroundColor,
  );


  @override
  State<StatefulWidget> createState() => ContainImageState();
}

class ContainImageState extends PhotoImageState<ContainImage> {

  Size onSetupImage(ui.Image image) {
    double width, height;
    width = widget.size.width;
    height = width * image.height / image.width;
    if (height > widget.size.height) {
      height = widget.size.height;
      width = height * image.width / image.height;
    }
    Size imageSize = Size(width, height);

    translation = Offset(widget.size.width - width, widget.size.height - height) / 2;
    if (imageSize.width > widget.size.width) {
      minScale = widget.size.width / imageSize.width;
    }
    if (imageSize.height > widget.size.height) {
      double scale = widget.size.height / imageSize.height;
      if (scale < minScale) {
        minScale = scale;
      }
    }
    return imageSize;
  }
}