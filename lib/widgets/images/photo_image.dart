
import 'package:flutter/cupertino.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as m64;

class PageRange {
  double start = 0;
  double get length => 1;
  double end = 1;
  bool reverse = false;

  static int ANIMATE = 1;
  static int SET_START = 2;

  bool arriveStart() => start <= 0;
  bool arriveEnd() =>  start + length >= end;

  List<void Function(double, int)> listeners = [];

  void addListener(void Function(double, int) listener) {
    listeners.add(listener);
  }

  void removeListener(void Function(double, int) listener) {
    listeners.remove(listener);
  }

  void onOffset(double offset, int state) {
    for (var ls in listeners) {
      ls(offset, state);
    }
  }

}

class PhotoImage extends StatefulWidget {
  final ImageProvider imageProvider;
  final Size size;
  final EdgeInsets padding;
  final WidgetBuilder loadingWidget;
  final WidgetBuilder errorWidget;
  final bool reverse;
  final bool initFromEnd;
  final PageRange range;

  PhotoImage({
    @required this.imageProvider,
    this.size,
    this.padding,
    this.loadingWidget,
    this.errorWidget,
    this.reverse,
    this.initFromEnd = false,
    PageRange range,
  }) : range = range == null ? PageRange() : range;

  @override
  State<StatefulWidget> createState() => _PhotoImageState();
}

class _PhotoImageState extends State<PhotoImage> with SingleTickerProviderStateMixin {

  ImageInfo _imageInfo;
  ImageStreamListener _imageStreamListener;
  ImageStream _imageStream;
  bool _hasError = false;

  AnimationController controller;

  Duration _duration = const Duration(milliseconds: 600);

  _PhotoImageState() {
    _imageStreamListener = ImageStreamListener(
        _getImage,
        onError: _getError
    );
  }

  void onOffset(double offset, int state) {
    var range = widget.range;
    double value;
    if (state & PageRange.SET_START == 0) {
      if (widget.reverse) {
        double maxWidth = widget.size.width - widget.padding.left - widget.padding.right;
        value = math.max(0, math.min(1, controller.value + (offset / maxWidth) / (range.end - range.length)));
      } else {
        double maxWidth = widget.size.width - widget.padding.left - widget.padding.right;
        value = math.max(0, math.min(1, controller.value - (offset / maxWidth) / (range.end - range.length)));
      }
    } else {
      value = offset / (range.end - range.length);
    }
    if ((state & PageRange.ANIMATE) != 0) {
      controller.animateTo(value, duration: _duration, curve: Curves.easeOutCubic);
    } else {
      controller.value = value;
    }
  }

  Offset _translation = Offset.zero;
  double _scale = 1;

  Offset _oldOffset = Offset.zero;
  double _oldScale = 1;

  Rect _imageRect;
  Size _imageSize;

  void _onScaleStart(ScaleStartDetails details) {
    _oldOffset = details.focalPoint;
    _oldScale = 1;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_imageRect != null) {
      setState(() {
        Offset offset = details.focalPoint - _oldOffset;
        _translation += offset;
        _oldOffset = details.focalPoint;
        var disScale = details.scale / _oldScale;
        var oldScale = _scale;
        _scale *= disScale;
        if (_scale < 1) {
          _scale = 1;
          disScale = _scale / oldScale;
        } else if (_scale > 4) {
          _scale = 4;
          disScale = _scale / oldScale;
        }
        _oldScale = details.scale;

        var offSize = _imageRect.size * (disScale - 1);
        var dx = -_translation.dx, dy = -_translation.dy;
        if (widget.reverse) {
          dx += _imageRect.width * _oldScale * (1 - widget.range.start + controller.value);
        } else {
          dx += _imageRect.width * _oldScale * (widget.range.start - controller.value);
        }

        dx += _imageSize.width / 2 * _oldScale;
        dy += _imageSize.height / 2 * _oldScale;

        var cSize = _imageRect.size * _oldScale;
        var off = Offset(offSize.width * dx / cSize.width, offSize.height * dy / cSize.height);
        _translation -= off;
        clampImage();
      });
    }
  }

  void clampImage() {
    double nx = _translation.dx, ny = _translation.dy;
    if (nx > 0) {
      nx = 0;
    }
    if (ny > 0) {
      ny = 0;
    }
    var size = _imageRect.size * _scale;
    if (nx < _imageSize.width - size.width) {
      nx = _imageSize.width - size.width;
    }
    if (ny < _imageSize.height - size.height) {
      ny = _imageSize.height - size.height;
    }
    _translation = Offset(nx, ny);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_imageRect != null) {

    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        child: Center(
          child: widget.errorWidget?.call(context),
        ),
      );
    } else {
      ui.Image image = _imageInfo?.image;
      double width, height;
      if (image != null) {
        double left = widget.padding.left, top = widget.padding.top,
            maxWidth = widget.size.width - widget.padding.left - widget.padding.right,
            maxHeight = widget.size.height - widget.padding.top - widget.padding.bottom;
        if (image.width / image.height < 1) {
          width = maxWidth;
          height = maxWidth * image.height / image.width;
          widget.range.end = 1;
          widget.range.start = 0;
        } else {
          height = maxHeight - 60;
          width = height * image.width / image.height;
          widget.range.end = width / maxWidth;
          widget.range.start = 0;
        }
        widget.range.reverse = widget.reverse;

        if (maxWidth > width) {
          left = (maxWidth - width) / 2 + widget.padding.left;
        }
        if (maxHeight > height) {
          top = (maxHeight - height) / 2 + widget.padding.top;
        }

        _imageRect = Rect.fromLTWH(left, top, width, height);
        _imageSize = Size(widget.size.width - left * 2, widget.size.height - top * 2);

        return GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              var range = widget.range;
              range.start = controller.value * (range.end - range.length);
              double tLeft = left, tTop = top;
              if (widget.reverse) {
                tLeft -= (range.end - range.length - range.start) * maxWidth;
              } else {
                tLeft -= range.start * maxWidth;
              }
              return Stack(
                children: [
                  Positioned(
                      left: tLeft,
                      top: tTop,
                      width: width,
                      height: height,
                      child: Transform(
                        transform: Matrix4.translation(m64.Vector3(_translation.dx, _translation.dy, 0))
                          ..scale(_scale, _scale),
                        child: child,
                      )
                  )
                ],
              );
            },
            child: Container(
              color: Colors.black,
              width: width,
              height: height,
              padding: EdgeInsets.all(1),
              child: RawImage(
                image: _imageInfo?.image,
                width: width - 2,
                height: height - 2,
                fit: BoxFit.fill,
              ),
            ),
          ),
        );

      } else {
        return Container(
          width: widget.size.width,
          child: Center(
            child: widget.loadingWidget?.call(context),
          ),
        );
      }
    }
  }

  void _getImage(ImageInfo image, bool synchronousCall) {
    setState(() {
      _imageInfo = image;
    });
  }

  void _getError(dynamic exception, StackTrace stackTrace) {
    setState(() {
      _hasError = true;
    });
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateImage();
  }

  @override
  void initState() {
    super.initState();
    widget.range.addListener(onOffset);
    controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300)
    );

    controller.value = widget.initFromEnd ? 1 : 0;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
    _imageStream?.removeListener(_imageStreamListener);
    widget.range.removeListener(onOffset);
  }

  @override
  void didUpdateWidget(PhotoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider) {
      _updateImage();
    }
    if (widget.range != oldWidget.range) {
      oldWidget.range.removeListener(onOffset);
      widget.range.addListener(onOffset);
    }
  }

  void _updateImage() {
    final ImageStream oldImageStream = _imageStream;
    _imageStream = widget.imageProvider.resolve(createLocalImageConfiguration(context));
    if (_imageStream.key != oldImageStream?.key) {
      _hasError = false;
      oldImageStream?.removeListener(_imageStreamListener);
      _imageStream.addListener(_imageStreamListener);
    }
  }
}