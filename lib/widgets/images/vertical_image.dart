
import 'package:kinoko/widgets/images/one_finger_zoom_gesture_recognizer.dart';

import '../over_drag.dart';
import 'photo_image.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class VerticalImage extends PhotoImage {

  VerticalImage({
    Key? key,
    required ImageProvider imageProvider,
    required Size size,
    WidgetBuilder? loadingWidget,
    WidgetBuilder? errorWidget,
    bool initFromEnd = false,
    PhotoImageController? controller,
    OneFingerCallback? onTap,
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
  );

  @override
  State<StatefulWidget> createState() => VerticalImageState();
}

class VerticalImageState extends PhotoImageState<VerticalImage> {

  @override
  bool arriveStart() {
    if (imageSize == Size.zero) return true;
    return translation.dy >= -0.01;
  }

  @override
  bool arriveEnd() {
    if (imageSize == Size.zero) return true;
    Size realSize = imageSize * scale;
    return translation.dy <= (widget.size.height - realSize.height + 0.01);
  }


  void next() {
    animateTo(Offset(translation.dx, _clampY(translation.dy - widget.size.height * 0.8)));
  }

  void prev() {
    animateTo(Offset(translation.dx, _clampY(translation.dy + widget.size.height * 0.8)));
  }

  void scrollOffset(double offset, bool animate) {
    if (animate) {
      animateTo(Offset(translation.dx, _clampY(translation.dy + offset)));
    } else {
      controller.stop();
      Offset trans = Offset(translation.dx, _clampY(translation.dy + offset));
      Offset off = trans - translation;
      setState(() {
        translation = trans;
      });
      OverDragUpdateNotification(off).dispatch(context);
    }
  }

  double _clampY(double dy) {
    Size realSize = (imageSize == Size.zero ? widget.size : imageSize) * scale;
    return math.min(math.max(dy, widget.size.height - realSize.height), 0);
  }

  Size onSetupImage(ui.Image image) {
    double width, height;
    width = widget.size.width;
    height = width * image.height / image.width;

    Size imageSize = Size(width, height);
    bool fromStart = !widget.reverse;
    if (widget.initFromEnd) {
      fromStart = !fromStart;
    }
    if (!fromStart) {
      translation = Offset(0, widget.size.height - height);
    }
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