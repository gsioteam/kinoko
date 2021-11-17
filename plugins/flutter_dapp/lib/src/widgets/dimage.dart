
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:js_script/js_script.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../dwidget.dart';

class DImage extends StatelessWidget {

  final String src;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Map<String, String>? headers;

  DImage({
    Key? key,
    required this.src,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.headers,
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
      return CachedNetworkImage(
        imageUrl: src,
        width: width,
        height: height,
        fit: fit,
        errorWidget: errorBuilder,
        httpHeaders: headers,
      );
    } else {
      var data = DWidget.of(context);
      return Image.file(File(data!.relativePath(src)),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }
  }
}