
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:js_script/js_script.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../dwidget.dart';

class DImage extends StatelessWidget {

  final String src;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Map<String, String>? headers;
  final bool gaplessPlayback;

  DImage({
    Key? key,
    required this.src,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.headers,
    this.gaplessPlayback = false,
  }): super(key: key);

  @override
  Widget build(BuildContext context) {
    var uri = Uri.parse(src);
    Widget errorBuilder(BuildContext context, data, stack) {
      return Container(
        width: width,
        height: height,
        child: Center(
          child: Icon(
            Icons.broken_image,
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
      );
    };
    if (uri.hasScheme) {
      return Image(
        image: CachedNetworkImageProvider(
          src,
          headers: headers,
        ),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
        gaplessPlayback: gaplessPlayback,
      );
    } else {
      var data = DWidget.of(context)!;
      var buf = data.script.fileSystems.cast<DappFileSystem>().loadFile(data.relativePath(src));
      if (buf != null) {
        return Image.memory(buf,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: errorBuilder,
          gaplessPlayback: gaplessPlayback,
        );
      } else {
        return errorBuilder(context, data, null);
      }
    }
  }
}