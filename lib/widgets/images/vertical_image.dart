
import '../over_drag.dart';
import 'photo_image.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class VerticalImage extends PhotoImage {

  VerticalImage({
    Key key,
    ImageProvider imageProvider,
    Size size,
    WidgetBuilder loadingWidget,
    WidgetBuilder errorWidget,
    bool initFromEnd,
    PhotoImageController controller,
  }) : super(
    key: key,
    imageProvider: imageProvider,
    size: size,
    loadingWidget: loadingWidget,
    errorWidget: errorWidget,
    initFromEnd: initFromEnd,
    controller: controller,
    reverse: false,
  );

  @override
  State<StatefulWidget> createState() => VerticalImageState();
}

class VerticalImageState extends PhotoImageState<VerticalImage> {

  @override
  bool arriveStart() {
    if (imageSize == null) return true;
    return translation.dy >= -0.01;
  }

  @override
  bool arriveEnd() {
    if (imageSize == null) return true;
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
    Size realSize = (imageSize ?? widget.size) * scale;
    return math.min(math.max(dy, widget.size.height - realSize.height), 0);
  }
}