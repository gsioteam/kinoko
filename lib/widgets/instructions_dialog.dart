
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:kinoko/utils/neo_cache_manager.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../localizations/localizations.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as Path;
import 'dart:math' as math;
import 'dart:ui' as ui;

Future<void> showInstructionsDialog(BuildContext context, String path, {
  String entry,
  Future<Rect> Function() onPop,
  Color iconColor = Colors.white
}) async {
  Completer<void> completer = Completer();
  GlobalKey<InstructionsDialogState> key = GlobalKey();

  Navigator.of(context).push(RawDialogRoute(
    transitionDuration: Duration(milliseconds: 240),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return Transform.translate(
        offset: Offset(0, (1-animation.value) * (animation.status == AnimationStatus.forward ? 200 : 0)),
        child: Opacity(
          opacity: animation.value,
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return InstructionsDialog(
        key: key,
        path: path,
        entry: entry,
        onFinish: onPop == null ? () {
          Navigator.of(context).pop();
          completer.complete();
        } : () async {
          Rect from = key.currentState?.getContentRect();
          ui.Image image = await key.currentState?.getContentImage();
          if (onPop == null || from == null) {
            Navigator.of(context).pop();
            completer.complete();
          } else {
            GlobalKey<_AnimationWidgetState> key = await transform(Overlay.of(context),
              from: from,
              image: image,
              iconColor: iconColor
            );
            Navigator.of(context).pop();
            Rect to = await onPop();
            await key.currentState.translateTo(to);
            completer.complete();
          }
        },
      );
    },
    barrierDismissible: false,
  ));

  return completer.future;
}

Future<GlobalKey<_AnimationWidgetState>> transform(OverlayState overlay, {
  Rect from,
  ui.Image image,
  Color iconColor
}) async {
  OverlayEntry entry;
  GlobalKey<_AnimationWidgetState> key = GlobalKey();
  entry = OverlayEntry(
    builder: (context) {
      return _AnimationWidget(
        key: key,
        from: from,
        image: image,
        iconColor: iconColor,
        onFinish: () {
          entry.remove();
        },
      );
    }
  );
  overlay.insert(entry);
  await Future.delayed(Duration(milliseconds: 100));
  return key;
}

class _AnimationWidget extends StatefulWidget {

  final Rect from;
  final ui.Image image;
  final VoidCallback onFinish;
  final Color iconColor;

  _AnimationWidget({
    Key key,
    this.from,
    this.image,
    this.onFinish,
    this.iconColor,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AnimationWidgetState();
}

class _AnimationWidgetState extends State<_AnimationWidget> with SingleTickerProviderStateMixin {
  AnimationController controller;
  Rect to;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double value = Curves.easeInOutCubic.transform(controller.value);
        bool notMove = to == null;
        Rect rect = notMove ? widget.from : Rect.lerp(widget.from, to, value);
        rect = Rect.fromLTWH(rect.left, rect.top - (math.sin(value * math.pi)) * 240, rect.width, rect.height);
        return Positioned.fromRect(
          rect: rect,
          child: Stack(
            children: [
              Opacity(
                opacity: notMove ? 0 : value,
                child: Center(
                  child: Icon(Icons.help_outline, color: widget.iconColor,),
                ),
              ),
              Opacity(
                opacity: 1 - value,
                child: child,
              )
            ],
          ),
        );
      },
      child: Container(
        color: Colors.white,
        child: RawImage(
          image: widget.image,
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 680),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> translateTo([Rect to]) async {
    this.to = to;
    await controller.forward(from: 0);
    widget.onFinish?.call();
  }
}

class InstructionsDialog extends StatefulWidget {

  final String path;
  final String entry;
  final VoidCallback onFinish;

  InstructionsDialog({
    Key key,
    this.path,
    this.entry,
    this.onFinish,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => InstructionsDialogState();
}

class InstructionsDialogState extends State<InstructionsDialog> {

  String content;
  GlobalKey contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    double height = math.min(MediaQuery.of(context).size.height * 0.6, 420);
    return Dialog(
      child: WillPopScope(
        child: RepaintBoundary(
          key: contentKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: height,
                padding: EdgeInsets.only(
                    left: 10,
                    right: 10,
                    bottom: 4
                ),
                child: content == null ?
                Center(
                  child: SpinKitRing(
                    size: 48,
                    color: Colors.black54,
                  ),
                ) : MarkdownWidget(
                  data: content,
                  styleConfig: StyleConfig(
                    imgBuilder: (url, attributes) {
                      var uri = Uri.parse(url);
                      return Container(
                        margin: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 2
                              )
                            ]
                        ),
                        child: uri.hasScheme ? Image(
                            image: NeoImageProvider(
                              uri: Uri.parse(url),
                              cacheManager: NeoCacheManager.defaultManager,
                            )
                        ):Image.asset(Path.join(widget.path, url)),
                      );
                    },
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MaterialButton(
                    textColor: Theme.of(context).primaryColor,
                    child: Text(kt("ok")),
                    onPressed: () {
                      widget.onFinish?.call();
                    },
                  )
                ],
              )
            ],
          ),
        ),
        onWillPop: () {
          widget.onFinish?.call();
          return SynchronousFuture<bool>(false);
        }
      ),

    );
  }

  @override
  void initState() {
    super.initState();

    rootBundle.loadString("${widget.path}/${widget.entry}.md").then((value) {
      setState(() {
        content = value;
      });
    });
  }

  Rect getContentRect() {
    final renderObject = contentKey.currentContext?.findRenderObject();
    var translation = renderObject?.getTransformTo(null)?.getTranslation();
    if (translation != null && renderObject.paintBounds != null) {
      return renderObject.paintBounds
          .shift(Offset(translation.x, translation.y));
    } else {
      return null;
    }
  }

  Future<ui.Image> getContentImage() {
    RenderRepaintBoundary boundary = contentKey.currentContext?.findRenderObject();
    return boundary?.toImage();
  }
}