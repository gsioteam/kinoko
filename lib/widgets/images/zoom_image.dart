
import 'package:flutter/cupertino.dart';

import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as m64;

import '../../localizations/localizations.dart';

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

  Size _imageSize;

  double _minScale = 1;
  double _maxScale = 4;

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
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
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

  Offset _oldScalePoint;
  double _oldScale;
  void _onScaleStart(ScaleStartDetails details) {
    _oldScalePoint = details.focalPoint;
    _oldScale = 1;
    print("ScaleStart");
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    print("ScaleUpdate");
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

  void clampImage() {
    _scale = math.min(math.max(_minScale, _scale), _maxScale);
    Size realSize = _imageSize * _scale;
    double nx = _translation.dx, ny = _translation.dy;
    if (nx > 0) {
      nx = 0;
    } else if (nx < _imageSize.width - realSize.width) {
      nx = _imageSize.width - realSize.width;
    }

    if (ny > 0) {
      ny = 0;
    } else if (ny < _imageSize.height - realSize.height) {
      ny = _imageSize.height - realSize.height;
    }
    _translation = Offset(nx, ny);
  }

  void _onScaleEnd(ScaleEndDetails details) {
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
}