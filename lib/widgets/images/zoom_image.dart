
import 'package:flutter/cupertino.dart';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as m64;

const double _ImageAspect = 1.55;

enum ImageFit {
  FitWidth,
}

class ZoomImage extends StatefulWidget {
  final ImageProvider imageProvider;
  final WidgetBuilder loadingWidget;
  final WidgetBuilder errorWidget;
  final ImageFit fit;

  ZoomImage({
    Key key,
    @required this.imageProvider,
    this.loadingWidget,
    this.errorWidget,
    this.fit = ImageFit.FitWidth,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ZoomImageState();
}

class _ZoomImageState extends State<ZoomImage> {

  ImageInfo _imageInfo;
  ImageStreamListener _imageStreamListener;
  ImageStream _imageStream;
  bool _hasError = false;

  Offset _translation = Offset.zero;
  double _scale = 1;

  Offset _oldOffset = Offset.zero;
  double _oldScale = 1;

  Size _imageSize;

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
        child: Center(
          child: widget.errorWidget?.call(context),
        ),
      );
    } else {
      ui.Image image = _imageInfo?.image;
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

        return GestureDetector(
          onScaleStart: _onStart,
          onScaleUpdate: _onUpdate,
          onScaleEnd: _onEnd,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.black,
            ),
            clipBehavior: Clip.antiAlias,
            child: Transform(
              transform: Matrix4.translation(m64.Vector3(_translation.dx, _translation.dy, 0))
                ..scale(_scale, _scale),
              child: Container(
                color: Colors.black,
                width: width,
                height: height,
                padding: EdgeInsets.all(1),
                child: RawImage(
                  image: image,
                  width: width - 2,
                  height: height - 2,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        );
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

  void _onStart(ScaleStartDetails details) {
    _oldOffset = details.focalPoint;
    _oldScale = 1;
  }

  void _onUpdate(ScaleUpdateDetails details) {
    if (_imageSize != null) {
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

        var offSize = _imageSize * (disScale - 1);
        var dx = -_translation.dx, dy = -_translation.dy;
        dx += _imageSize.width * _oldScale * (0.5);

        dx += _imageSize.width / 2 * _oldScale;
        dy += _imageSize.height / 2 * _oldScale;

        var cSize = _imageSize * _oldScale;
        var off = Offset(offSize.width * dx / cSize.width, offSize.height * dy / cSize.height);
        _translation -= off;
        clampImage();
      });
    }
  }

  void _onEnd(ScaleEndDetails details) {

  }

  void clampImage() {
    double nx = _translation.dx, ny = _translation.dy;
    if (nx > 0) {
      nx = 0;
    }
    if (ny > 0) {
      ny = 0;
    }
    var size = _imageSize * _scale;
    if (nx < _imageSize.width - size.width) {
      nx = _imageSize.width - size.width;
    }
    if (ny < _imageSize.height - size.height) {
      ny = _imageSize.height - size.height;
    }
    _translation = Offset(nx, ny);
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateImage();
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
}