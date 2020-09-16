
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';

ImageProvider makeImageProvider(String url) {
  Uri uri = Uri.parse(url);
  if (RegExp(r"\.svg", caseSensitive: false).hasMatch(uri.path)) {
    if (uri.scheme == "http" || uri.scheme == "https") {
      return Svg.network(url);
    } else if (url[0] == '/') {
      return Svg.file(url);
    } else {
      return Svg.asset(url);
    }
  } else {
    if (uri.scheme == "http" || uri.scheme == "https") {
      return CachedNetworkImageProvider(url);
    } else if (url[0] == '/') {
      return FileImage(File(url));
    } else {
      return AssetImage(url);
    }
  }
}