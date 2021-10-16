
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:glib/main/project.dart';
import 'package:kinoko/utils/neo_cache_manager.dart';

ImageProvider makeImageProvider(String url) {
  if (url?.startsWith("/") == true) {
    return FileImage(File("${WebImage.currentProject?.fullpath}$url"));
  }
  Uri uri = Uri.parse(url);
  if (RegExp(r"\.svg", caseSensitive: false).hasMatch(uri.path)) {
    if (uri.hasScheme) {
      if (uri.scheme == "asset") {
        return Svg.asset(url);
      } else {
        return Svg.network(url);
      }
    } else {
      return Svg.file(url);
    }
  } else {
    if (uri.hasScheme) {
      if (uri.scheme == "asset") {
        return AssetImage(url);
      } else {
        return NeoImageProvider(
          uri: Uri.parse(url),
          cacheManager: NeoCacheManager.defaultManager
        );
      }
    } else {
      return FileImage(File(url));
    }
  }
}

class WebImage extends StatelessWidget {

  final String url;
  final double width;
  final double height;
  final BoxFit fit;

  static Project _currentProject;
  static Project get currentProject => _currentProject;
  static set currentProject(Project project) {
    _currentProject?.release();
    _currentProject = project?.control();
  }

  WebImage({
    @required this.url,
    this.width = 36,
    this.height = 36,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        width: width??0,
        height: height??0,
      );
    } else {
      return Image(
        image: makeImageProvider(url),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, e, stack) {
          return Container(
            width: width,
            height: height,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Center(
              child: Icon(
                Icons.broken_image,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          );
        },
      );
    }
  }
}