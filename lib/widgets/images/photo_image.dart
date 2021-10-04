
import 'package:flutter/cupertino.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as m64;

import '../../localizations/localizations.dart';

const double _ImageAspect = 1.55;

class PhotoImageController {

  static const int ANIMATE = 1;
  static const int SET_START = 2;

  _PhotoImageState state;

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

  PhotoImage({
    Key key,
    @required this.imageProvider,
    this.size,
    this.loadingWidget,
    this.errorWidget,
    this.reverse,
    this.initFromEnd = false,
    PhotoImageController controller,
  }) : controller = controller == null ? PhotoImageController() : controller, super(key: key);

  @override
  State<StatefulWidget> createState() => _PhotoImageState();
}

class _PhotoImageState extends State<PhotoImage> with SingleTickerProviderStateMixin {

  ImageInfo _imageInfo;
  ImageStreamListener _imageStreamListener;
  ImageStream _imageStream;
  bool _hasError = false;

  AnimationController controller;

  _PhotoImageState() {
    _imageStreamListener = ImageStreamListener(
        _getImage,
        onError: _getError
    );
  }

  Offset _animateStart = Offset.zero;
  Offset _animateEnd = Offset.zero;
  Offset _translation = Offset.zero;
  double _scale = 1;

  Size _imageSize;

  GlobalKey _key = GlobalKey();

  double _minScale = 1;
  double _maxScale = 4;

  Offset _oldScalePoint;
  double _oldScale;
  void _onScaleStart(ScaleStartDetails details) {
    controller.stop();
    _oldScalePoint = details.focalPoint;
    _oldScale = 1;
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

  void clampImage() {
    _scale = math.min(math.max(_minScale, _scale), _maxScale);
    Size realSize = _imageSize * _scale;
    double nx = _translation.dx, ny = _translation.dy;
    if (realSize.width < widget.size.width) {
      nx = (widget.size.width - realSize.width) / 2;
    } else {
      if (nx > 0) {
        nx = 0;
      } else if (nx < widget.size.width - realSize.width) {
        nx = widget.size.width - realSize.width;
      }
    }
    if (realSize.height < widget.size.height) {
      ny = (widget.size.height - realSize.height) / 2;
    } else {
      if (ny > 0) {
        ny = 0;
      } else if (ny < widget.size.height - realSize.height) {
        ny = widget.size.height - realSize.height;
      }
    }
    _translation = Offset(nx, ny);
  }

  void _onScaleEnd(ScaleEndDetails details) {
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
          double width, height;
          if (image.width > image.height) {
            height = math.min(widget.size.width * _ImageAspect, widget.size.height);
            width = height * image.width / image.height;
          } else {
            width = widget.size.width;
            height = width * image.height / image.width;
          }

          _imageSize = Size(width, height);
          bool fromStart = !widget.reverse;
          if (widget.initFromEnd) {
            fromStart = !fromStart;
          }
          if (!fromStart) {
            _translation = Offset(widget.size.width - width, 0);
            _animateStart = _translation;
          }
          if (_imageSize.width > widget.size.width) {
            _minScale = widget.size.width / _imageSize.width;
          }
          if (_imageSize.height > widget.size.height) {
            double scale = widget.size.height / _imageSize.height;
            if (scale < _minScale) {
              _minScale = scale;
            }
          }
          clampImage();
        }

        return Container(
          width: widget.size.width,
          height: widget.size.height,
          decoration: BoxDecoration(
            color: Colors.black,
          ),
          clipBehavior: Clip.antiAlias,
          child: GestureDetector(
            key: _key,
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            child: OverflowBox(
              minWidth: math.min(_imageSize.width, widget.size.width),
              minHeight: math.min(_imageSize.height, widget.size.height),
              maxWidth: _imageSize.width,
              maxHeight: _imageSize.height,
              alignment: Alignment.topLeft,
              child: Transform(
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
            ),
          ),
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
      _imageStream.addListener(_imageStreamListener);
    }
  }

  bool arriveStart() {
    if (_imageSize == null) return true;
    if (widget.reverse) {
      Size realSize = _imageSize * _scale;
      return _translation.dx <= (widget.size.width - realSize.width + 0.01);
    } else {
      return _translation.dx >= -0.01;
    }
  }

  bool arriveEnd() {
    if (_imageSize == null) return true;
    if (widget.reverse) {
      return _translation.dx >= -0.01;
    } else {
      Size realSize = _imageSize * _scale;
      return _translation.dx <= (widget.size.width - realSize.width + 0.01);
    }
  }

  void next() {
    if (widget.reverse) {
      _animateStart = _translation;
      _animateEnd = Offset(_clampX(_translation.dx + widget.size.width * 0.8), _translation.dy);
    } else {
      _animateStart = _translation;
      _animateEnd = Offset(_clampX(_translation.dx - widget.size.width * 0.8), _translation.dy);
    }
    controller.forward(from: 0);
  }

  void prev() {
    if (widget.reverse) {
      _animateStart = _translation;
      _animateEnd = Offset(_clampX(_translation.dx - widget.size.width * 0.8), _translation.dy);
    } else {
      _animateStart = _translation;
      _animateEnd = Offset(_clampX(_translation.dx + widget.size.width * 0.8), _translation.dy);
    }
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
    if (animate) {
      _animateStart = _translation;
      _animateEnd = Offset(
          _clampX(_translation.dx + offset),
          _translation.dy);
      controller.forward(from: 0);
    } else {
      controller.stop();
      setState(() {
        _translation = Offset(
            _clampX(_translation.dx + offset),
            _translation.dy);
        _animateStart = _animateEnd = _translation;
      });
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