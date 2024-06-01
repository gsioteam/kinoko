
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as m64;

import '../../localizations/localizations.dart';
import 'one_finger_zoom_gesture_recognizer.dart';

const double _ImageAspect = 1.55;

enum ImageFit {
  FitWidth,
}

class ZoomImage extends StatefulWidget {
  final ImageProvider imageProvider;
  final WidgetBuilder? loadingWidget;
  final WidgetBuilder? errorWidget;
  final ImageFit fit;
  final OneFingerCallback? onTap;
  final EdgeInsets padding;

  ZoomImage({
    Key? key,
    required this.imageProvider,
    this.loadingWidget,
    this.errorWidget,
    this.fit = ImageFit.FitWidth,
    this.onTap,
    this.padding = const EdgeInsets.all(1),
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ZoomImageState();
}

const double _zoomScale = 2.5;
const Duration _moveDuration = Duration(milliseconds: 200);

class _ZoomImageState extends State<ZoomImage> {

  ImageInfo? _imageInfo;
  late ImageStreamListener _imageStreamListener;
  ImageStream? _imageStream;
  bool _hasError = false;

  Offset _translation = Offset.zero;
  double _scale = 1;

  Size _imageSize = Size.zero;

  double _minScale = 1;
  double _maxScale = 4;

  Duration _animationDuration = Duration.zero;

  _ZoomImageState() {
    _imageStreamListener = ImageStreamListener(
        _getImage,
        onError: _getError
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    if (_hasError) {
      return Container(
        width: screenSize.width,
        height: screenSize.width * _ImageAspect,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.errorWidget != null) widget.errorWidget!.call(context),
            Padding(
              padding: EdgeInsets.only(top: 5),
              child: OutlinedButton(
                onPressed: () {
                  reload();
                },
                child: Text(kt("reload")),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white,
                    )
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      ui.Image? image = _imageInfo?.image;
      if (image != null) {
        double width;
        double height;
        switch (widget.fit) {
          case ImageFit.FitWidth: {
            width = screenSize.width;
            height = width * image.height / image.width;
          }
        }
        _imageSize = Size(width, height);

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

        return buildGestureDetector(Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.black,
          ),
          clipBehavior: Clip.antiAlias,
          child: AnimatedContainer(
            duration: _animationDuration,
            transform: Matrix4.translation(m64.Vector3(_translation.dx, _translation.dy, 0))
              ..scale(_scale, _scale),
            child: Container(
              color: Colors.black,
              width: width,
              height: height,
              padding: widget.padding,
              child: RawImage(
                image: image,
                width: width - 2,
                height: height - 2,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),);
      } else {
        return Container(
          width: screenSize.width,
          height: screenSize.width * _ImageAspect,
          child: Center(
            child: widget.loadingWidget?.call(context),
          ),
        );
      }
    }
  }

  Offset _oldScalePoint = Offset.zero;
  double _oldScale = 1;
  void _onScaleStart(ScaleStartDetails details) {
    _oldScalePoint = details.focalPoint;
    _oldScale = 1;
    _animationDuration = Duration.zero;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    _animationDuration = Duration.zero;
    setState(() {
      Offset offset = details.focalPoint - _oldScalePoint;
      _translation += offset;

      Size screenSize = _imageSize;
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
    _scale = math.min(math.max(_minScale, _scale), _maxScale);
    Offset insetOffset = Offset(inset * 2, inset * 2);
    Size realSize = _imageSize * _scale + insetOffset;
    double nx = _translation.dx, ny = _translation.dy;
    if (nx > insetOffset.dx) {
      nx = insetOffset.dx;
    } else if (nx < _imageSize.width - realSize.width) {
      nx = _imageSize.width - realSize.width;
    }

    if (ny > insetOffset.dy) {
      ny = insetOffset.dy;
    } else if (ny < _imageSize.height - realSize.height) {
      ny = _imageSize.height - realSize.height;
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
      Offset anchor = (event.localPosition - _translation) / _scale;
      double oldScale = _scale;
      _scale = 1;
      Size extendSize = _imageSize * (_scale - oldScale);

      _translation -= Offset(
        extendSize.width * anchor.dx / _imageSize.width,
        extendSize.height * anchor.dy / _imageSize.height,
      );
      clampImage();
    });
  }

  void _getImage(ImageInfo image, bool synchronousCall) {
    setState(() {
      _imageInfo = image;
    });
  }

  void _getError(dynamic exception, StackTrace? stackTrace) {
    setState(() {
      _hasError = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateImage();
  }

  void _updateImage() {
    final ImageStream? oldImageStream = _imageStream;
    _imageStream = widget.imageProvider.resolve(createLocalImageConfiguration(context));
    if (_imageStream!.key != oldImageStream?.key) {
      _hasError = false;
      oldImageStream?.removeListener(_imageStreamListener);
      _imageStream!.addListener(_imageStreamListener);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _imageStream?.removeListener(_imageStreamListener);
  }

  @override
  void didUpdateWidget(covariant ZoomImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider) {
      _updateImage();
    }
  }

  void reload() {
    if (_hasError) {
      setState(() {
        _hasError = false;
        _imageStream?.removeListener(_imageStreamListener);
        widget.imageProvider.evict();
        _imageStream = widget.imageProvider.resolve(createLocalImageConfiguration(context));
        _imageStream!.addListener(_imageStreamListener);
      });
    }
  }
}