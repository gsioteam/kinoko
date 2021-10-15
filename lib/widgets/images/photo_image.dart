
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kinoko/widgets/over_drag.dart';
import 'package:vector_math/vector_math_64.dart' as m64;

import 'one_finger_zoom_gesture_recognizer.dart';
import '../../localizations/localizations.dart';

const double ImageAspect = 1.55;

class PhotoImageController {

  PhotoImageState state;

  bool arriveStart() => state?.arriveStart() ?? true;
  bool arriveEnd() =>  state?.arriveEnd() ?? true;

  void scrollOffset(double offset, bool animate) => state?.scrollOffset(offset, animate);
  void next() => state?.next();
  void prev() => state?.prev();

  void reload() => state?.reload();
}

class PhotoImage extends StatefulWidget {
  final ImageProvider imageProvider;
  final Size size;
  final WidgetBuilder loadingWidget;
  final WidgetBuilder errorWidget;
  final bool reverse;
  final bool initFromEnd;
  final PhotoImageController controller;
  final OneFingerCallback onTap;
  final AxisDirection direction;

  PhotoImage({
    Key key,
    @required this.imageProvider,
    this.size,
    this.loadingWidget,
    this.errorWidget,
    this.reverse,
    this.initFromEnd = false,
    PhotoImageController controller,
    this.direction,
    this.onTap,
  }) : controller = controller == null ? PhotoImageController() : controller, super(key: key);

  @override
  State<StatefulWidget> createState() => PhotoImageState();
}

const double _zoomScale = 2.5;
const Duration _moveDuration = Duration(milliseconds: 200);

class PhotoImageState<T extends PhotoImage> extends State<T> with SingleTickerProviderStateMixin {

  ImageInfo _imageInfo;
  ImageStreamListener _imageStreamListener;
  ImageStream _imageStream;
  bool _hasError = false;

  AnimationController controller;

  PhotoImageState() {
    _imageStreamListener = ImageStreamListener(
        _getImage,
        onError: _getError
    );
  }

  Offset _animateStart = Offset.zero;
  Offset _animateEnd = Offset.zero;
  Offset _translation = Offset.zero;
  double _scale = 1;
  double get scale => _scale;

  Size _imageSize;
  Size get imageSize => _imageSize;

  Offset get translation => _translation;
 set translation(v) => _translation = v;

  GlobalKey _key = GlobalKey();

  double minScale = 1;
  double maxScale = 4;

  Offset _oldScalePoint;
  double _oldScale;

  Duration _animationDuration = Duration.zero;

  void _onScaleStart(ScaleStartDetails details) {
    controller.stop();
    _oldScalePoint = details.focalPoint;
    _oldScale = 1;
    _animationDuration = Duration.zero;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      Offset offset = details.focalPoint - _oldScalePoint;
      _translation += offset;

      Size screenSize = widget.size;
      Offset localFocalPoint = details.localFocalPoint;
      if (_imageSize.height < screenSize.height) {
        localFocalPoint -= Offset(0, (screenSize.height - _imageSize.height) / 2);
      }
      Offset anchor = (localFocalPoint - _translation) / _scale;
      double oldScale = _scale;
      _scale *= (details.scale / _oldScale);
      Size extendSize = _imageSize * (_scale - oldScale);


      _translation -= Offset(
        extendSize.width * anchor.dx / _imageSize.width,
        extendSize.height * anchor.dy / _imageSize.height,
      );
      clampImage();

      _oldScalePoint = details.focalPoint;
      _oldScale = details.scale;
    });
  }

  void clampImage([double inset = 0]) {
    _scale = math.min(math.max(minScale, _scale), maxScale);
    Offset insetOffset = Offset(inset * 2, inset * 2);
    Size realSize = _imageSize * _scale + insetOffset;
    double nx = _translation.dx, ny = _translation.dy;
    if (realSize.width < widget.size.width) {
      nx = (widget.size.width - realSize.width) / 2;
    } else {
      if (nx > insetOffset.dx) {
        nx = insetOffset.dx;
      } else if (nx < widget.size.width - realSize.width) {
        nx = widget.size.width - realSize.width;
      }
    }
    if (realSize.height < widget.size.height) {
      ny = (widget.size.height - realSize.height) / 2;
    } else {
      if (ny > insetOffset.dy) {
        ny = insetOffset.dy;
      } else if (ny < widget.size.height - realSize.height) {
        ny = widget.size.height - realSize.height;
      }
    }
    _translation = Offset(nx, ny);
  }

  void _onScaleEnd(ScaleEndDetails details) {
  }

  void _onOneFingerZoomStart(PointerEvent event) {
    _animationDuration = _moveDuration;
    setState(() {
      Offset anchor = (event.localPosition - _translation) / _scale;
      double oldScale = _scale;
      _scale = _zoomScale;
      Size extendSize = _imageSize * (_scale - oldScale);

      _translation -= Offset(
        extendSize.width * anchor.dx / _imageSize.width,
        extendSize.height * anchor.dy / _imageSize.height,
      );
      clampImage();

      _oldScalePoint = event.localPosition;
    });
  }
  void _onOneFingerZoomUpdate(PointerEvent event) {
    // _animationDuration = Duration.zero;
    setState(() {
      _translation -= (event.localPosition - _oldScalePoint) * _scale;
      clampImage(40);
      _oldScalePoint = event.localPosition;
    });

  }
  void _onOneFingerZoomEnd(PointerEvent event) {
    _animationDuration = _moveDuration;
    setState(() {
      _scale = 1;
      clampImage();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        width: widget.size.width,
        height: widget.size.height,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.errorWidget?.call(context),
              Padding(
                padding: EdgeInsets.only(top: 5),
                child: OutlinedButton(
                  onPressed: () {
                    reload();
                  },
                  child: Text(kt("reload")),
                  style: OutlinedButton.styleFrom(
                      primary: Colors.white,
                      side: BorderSide(
                        color: Colors.white,
                      )
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ui.Image image = _imageInfo?.image;
      if (image != null) {
        if (_imageSize == null) {
          _imageSize = onSetupImage(image);
          clampImage();
        }

        Widget buildGestureDetector(Widget child) {
          return RawGestureDetector(
            gestures: {
              ScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
                  () => ScaleGestureRecognizer(),
                  (instance) {
                    instance.onStart = _onScaleStart;
                    instance.onUpdate = _onScaleUpdate;
                    instance.onEnd = _onScaleEnd;
                  },
              ),
              OneFingerZoomGestureRecognizer: GestureRecognizerFactoryWithHandlers<OneFingerZoomGestureRecognizer>(
                  () => OneFingerZoomGestureRecognizer(),
                  (instance) {
                    instance.onStart = _onOneFingerZoomStart;
                    instance.onUpdate = _onOneFingerZoomUpdate;
                    instance.onEnd = _onOneFingerZoomEnd;
                    instance.onTap = widget.onTap;
                  }
              ),
            },
            child: child,
          );
        }

        return Container(
          width: widget.size.width,
          height: widget.size.height,
          decoration: BoxDecoration(
            color: Colors.black,
          ),
          clipBehavior: Clip.antiAlias,
          child: buildGestureDetector(OverflowBox(
            minWidth: math.min(_imageSize.width, widget.size.width),
            minHeight: math.min(_imageSize.height, widget.size.height),
            maxWidth: _imageSize.width,
            maxHeight: _imageSize.height,
            alignment: Alignment.topLeft,
            child: AnimatedContainer(
              duration: _animationDuration,
              transform: Matrix4.translation(m64.Vector3(_translation.dx, _translation.dy, 0))
                ..scale(_scale, _scale),
              child: Container(
                color: Colors.black,
                width: _imageSize.width,
                height: _imageSize.height,
                padding: const EdgeInsets.all(1),
                child: RawImage(
                  image: _imageInfo?.image,
                  width: _imageSize.width - 2,
                  height: _imageSize.height - 2,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),),
        );

      } else {
        return Container(
          width: widget.size.width,
          height: widget.size.height,
          child: Center(
            child: widget.loadingWidget?.call(context),
          ),
        );
      }
    }
  }

  Size onSetupImage(ui.Image image) {
    double width, height;
    if (image.width > image.height) {
      height = math.min(widget.size.width * ImageAspect, widget.size.height);
      width = height * image.width / image.height;
    } else {
      width = widget.size.width;
      height = width * image.height / image.width;
    }

    Size imageSize = Size(width, height);
    bool fromStart = !widget.reverse;
    if (widget.initFromEnd) {
      fromStart = !fromStart;
    }
    if (widget.direction == AxisDirection.left) {
      fromStart = !fromStart;
    }
    if (!fromStart) {
      _translation = Offset(widget.size.width - width, 0);
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
    widget.controller.state = this;
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    controller.value = widget.initFromEnd ? 1 : 0;
    controller.addListener(_onAnimation);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
    _imageStream?.removeListener(_imageStreamListener);
    if (widget.controller.state == this)
      widget.controller.state = null;
  }

  @override
  void didUpdateWidget(PhotoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider) {
      _updateImage();
    }
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller.state == this)
        oldWidget.controller.state = null;
      widget.controller.state = this;
    }
  }

  void _updateImage() {
    final ImageStream oldImageStream = _imageStream;
    _imageStream = widget.imageProvider.resolve(createLocalImageConfiguration(context));
    if (_imageStream.key != oldImageStream?.key) {
      _hasError = false;
      oldImageStream?.removeListener(_imageStreamListener);
      if (_imageStreamListener != null)
        _imageStream.addListener(_imageStreamListener);
    }
  }

  bool arriveStart() {
    if (_imageSize == null) return true;
    bool check = widget.reverse;
    if (widget.direction == AxisDirection.left)
      check = !check;
    if (check) {
      Size realSize = _imageSize * _scale;
      return _translation.dx <= (widget.size.width - realSize.width + 0.01);
    } else {
      return _translation.dx >= -0.01;
    }
  }

  bool arriveEnd() {
    if (_imageSize == null) return true;
    bool check = widget.reverse;
    if (widget.direction == AxisDirection.left)
      check = !check;
    if (check) {
      return _translation.dx >= -0.01;
    } else {
      Size realSize = _imageSize * _scale;
      return _translation.dx <= (widget.size.width - realSize.width + 0.01);
    }
  }

  void next() {
    bool check = widget.reverse;
    if (widget.direction == AxisDirection.left)
      check = !check;
    if (check) {
      animateTo(Offset(_clampX(_translation.dx + widget.size.width * 0.8), _translation.dy));
    } else {
      animateTo(Offset(_clampX(_translation.dx - widget.size.width * 0.8), _translation.dy));
    }
  }

  void prev() {
    bool check = widget.reverse;
    if (widget.direction == AxisDirection.left)
      check = !check;
    if (check) {
      animateTo(Offset(_clampX(_translation.dx - widget.size.width * 0.8), _translation.dy));
    } else {
      animateTo(Offset(_clampX(_translation.dx + widget.size.width * 0.8), _translation.dy));
    }
  }

  void animateTo(Offset translation) {
    _animationDuration = Duration.zero;
    _animateStart = _translation;
    _animateEnd = translation;
    controller.forward(from: 0);
  }

  void reload() {
    if (_hasError) {
      setState(() {
        _hasError = false;
        _imageStream.removeListener(_imageStreamListener);
        widget.imageProvider.evict();
        _imageStream = widget.imageProvider.resolve(createLocalImageConfiguration(context));
        _imageStream.addListener(_imageStreamListener);
      });
    }
  }

  void scrollOffset(double offset, bool animate) {
    _animationDuration = Duration.zero;
    if (widget.direction == AxisDirection.left) {
      offset = -offset;
    }
    if (animate) {
      _animateStart = _translation;
      _animateEnd = Offset(
          _clampX(_translation.dx + offset),
          _translation.dy);
      controller.forward(from: 0);
    } else {
      controller.stop();
      Offset trans = Offset(
          _clampX(_translation.dx + offset),
          _translation.dy);
      Offset off = trans - _translation;
      setState(() {
        _translation = trans;
        _animateStart = _animateEnd = _translation;
      });
      OverDragUpdateNotification(off).dispatch(context);
    }
  }

  double _clampX(double dx) {
    Size realSize = (_imageSize ?? widget.size) * _scale;
    return math.min(math.max(dx, widget.size.width - realSize.width), 0);
  }

  void _onAnimation() {
    setState(() {
      _translation = Offset.lerp(_animateStart, _animateEnd, controller.value);
    });
  }
}