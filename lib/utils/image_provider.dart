
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:glib/main/project.dart';
import 'package:crypto/crypto.dart';

import 'neo_cache_manager.dart';

String generateMd5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}

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
      return NeoImageProvider(
        uri: uri,
        cacheManager: NeoCacheManager.defaultManager
      );
    } else if (url[0] == '/') {
      return FileImage(File(url));
    } else {
      return AssetImage(url);
    }
  }
}

ImageProvider projectImageProvider(Project project) {
  String icon = project?.icon;
  if (icon != null && icon.isNotEmpty) {
    return makeImageProvider(icon);
  }
  if (project.isValidated) {
    String iconpath = project.fullpath + "/icon.png";
    File icon = new File(iconpath);
    if (icon.existsSync()) {
      return FileImage(icon);
    } else if (project.icon.isNotEmpty) {
      return makeImageProvider(project.icon);
    }
  }
  return NeoImageProvider(
      uri: Uri.parse("https://www.tinygraphs.com/squares/${generateMd5(project.url)}?theme=bythepool&numcolors=3&size=180&fmt=jpg"),
      cacheManager: NeoCacheManager.defaultManager
  );
}
