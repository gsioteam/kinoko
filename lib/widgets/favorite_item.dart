

import 'package:decorated_icon/decorated_icon.dart';
import 'package:flutter/material.dart';
import 'package:kinoko/localizations/localizations.dart';
import 'dart:ui' as ui;

import '../utils/favorites_manager.dart';
import '../utils/neo_cache_manager.dart';

const Size _containerSize = Size(120, 180);
const double _frameOffset = 5;

class BookFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(_frameOffset, -_frameOffset);
    path.lineTo(_frameOffset + size.width, -_frameOffset);
    path.lineTo(_frameOffset + size.width, -_frameOffset + size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    Paint paint = Paint();
    paint.style = PaintingStyle.fill;
    paint.shader = ui.Gradient.linear(
      Offset(0, 0),
      Offset(size.width, size.height),
      [
        Color(0xffeeeeee),
        Color(0xff666666),
      ],
    );
    canvas.drawPath(path, paint);

    paint = Paint();
    paint.style = PaintingStyle.stroke;
    paint.strokeJoin = StrokeJoin.round;
    paint.strokeCap = StrokeCap.round;
    paint.color = Color(0xff666666);
    paint.shader = null;
    paint.strokeWidth = 1;
    canvas.drawPath(path, paint);

    {
      paint.strokeWidth = 2;
      Path path = Path();
      path.moveTo(1, -0);
      path.lineTo(size.width + 0, -0);
      path.lineTo(size.width + 0, size.height - 1);
      canvas.drawPath(path, paint);
    }

    {
      paint = Paint();
      paint.style = PaintingStyle.fill;
      paint.color = Color(0xffaaaaaa);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

abstract class FavoriteItemData implements Listenable {
  ImageProvider get imageProvider;
  String get title;
  String get subtitle;
  bool get hasNew;

  bool get hasData;
}

class FavoriteItem extends StatefulWidget {
  final VoidCallback? onTap;
  final FavoriteItemData item;
  final VoidCallback? onDismiss;
  final VoidCallback? onMoveToFirst;

  FavoriteItem({
    Key? key,
    this.onTap,
    required this.item,
    this.onDismiss,
    this.onMoveToFirst,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FavoriteItemState();
}

class _FavoriteItemState extends State<FavoriteItem> {

  bool highlight = false;
  GlobalKey _itemKey = GlobalKey();

  @override
  Widget build(BuildContext context) {

    return InkWell(
      child: Container(
        padding: EdgeInsets.all(14),
        child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Container(
                width: _containerSize.width,
                height: _containerSize.height,
                key: _itemKey,
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                          color: Theme.of(context).shadowColor,
                          offset: Offset(6, 6),
                          blurRadius: 6
                      ),
                    ]
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        size: _containerSize,
                        painter: BookFramePainter(),
                        child: !widget.item.hasData ? Container(
                          color: Colors.grey,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                        ) : Image(
                          image: widget.item.imageProvider,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          width: _containerSize.width,
                          height: _containerSize.height,
                          errorBuilder: (context, e, stack) {
                            return Container(
                              color: Colors.grey,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: -1,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                            color: Colors.orange,
                            boxShadow: [
                              BoxShadow(
                                  offset: Offset(0, 1)
                              )
                            ]
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.item.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Padding(padding: EdgeInsets.only(top: 2)),
                            Text(
                              widget.item.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Visibility(
                      visible: widget.item.hasNew,
                      child: Positioned(
                        top: -6,
                        right: 5,
                        child: DecoratedIcon(
                          Icons.bookmark_sharp,
                          color: Colors.red,
                          size: 36,
                          shadows: [
                            BoxShadow(
                                offset: Offset(1, 1)
                            )
                          ],
                        ),
                      ),
                    ),
                    // Visibility(
                    //   visible: widget.item.value,
                    //   child: Positioned.fill(
                    //     child: Container(
                    //       color: Colors.black12,
                    //       child: SpinKitFadingCircle(
                    //         size: 36,
                    //         color: Colors.white,
                    //       ),
                    //     )
                    //   ),
                    // ),
                  ],
                ),
              ),
            )
        ),
      ),
      onTap: widget.onTap,
      onLongPress: () async {
        var renderObject = _itemKey.currentContext?.findRenderObject();
        if (renderObject != null) {
          var rect = renderObject.semanticBounds;
          var transform = renderObject.getTransformTo(null);
          Offset point = rect.center;
          var res = transform.applyToVector3Array([point.dx, point.dy, 0]);
          var ret = await showMenu<int>(
            context: context,
            position: RelativeRect.fromLTRB(
              res[0] - 20,
              res[1],
              res[0],
              res[1] + 20,
            ),
            items: [
              PopupMenuItem(
                child: Text(kt('move_to_first')),
                value: 0,
              ),
              PopupMenuItem(
                child: Text(kt('remove')),
                value: 1,
              ),
            ],
          );
          if (ret != null) {
            switch (ret) {
              case 0: {
                widget.onMoveToFirst?.call();
                break;
              }
              case 1: {
                widget.onDismiss?.call();
                break;
              }
            }
          }
        }
      },
    );
  }

  onStateChanged() {
    setState(() { });
  }

  @override
  void initState() {
    super.initState();
    widget.item.addListener(onStateChanged);
  }

  @override
  void dispose() {
    super.dispose();
    widget.item.removeListener(onStateChanged);
  }

  @override
  void didUpdateWidget(FavoriteItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      oldWidget.item.removeListener(onStateChanged);

      widget.item.addListener(onStateChanged);
    }
  }

}