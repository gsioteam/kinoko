
import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart' as svg_provider;
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import 'plugin/plugin.dart';

String _generateMd5(String str) =>
    hex.encode(md5.convert(utf8.encode(str)).bytes);

Widget buildIdenticon(String? identifier, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
}) {
  return SvgPicture.string(
    Jdenticon.toSvg(_generateMd5(identifier ?? "null")),
    width: width,
    height: height,
    fit: fit,
  );
}

Widget pluginImage(Plugin? plugin, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  if (plugin?.isValidate == true) {
    if (plugin!.information!.icon != null) {
      String icon = plugin.information!.icon!;
      Uri uri = Uri.parse(icon);
      if (uri.hasScheme) {
        return CachedNetworkImage(
          imageUrl: uri.toString(),
          width: width,
          height: height,
          fit: fit,
          errorWidget: errorBuilder == null ? null : (context, url, error) {
            return errorBuilder(context, error, null);
          },
        );
      } else {
        if (icon[0] != '/') {
          icon = '/' + icon;
        }
        if (plugin.fileSystem.exist(icon)) {
          return Image.memory(
            Uint8List.fromList(plugin.fileSystem.readBytes(icon)!),
            width: width,
            height: height,
            fit: fit,
          );
        }
      }
    }
    if (plugin.fileSystem.exist("/icon.png")) {
      return Image.memory(
        plugin.fileSystem.readBytes("/icon.png")!,
        width: width,
        height: height,
        fit: fit,
      );
    }
  }

  return buildIdenticon(
    plugin?.id,
    width: width,
    height: height,
    fit: fit,
  );
}

ImageProvider networkImageProvider(String url) {
  Uri uri = Uri.parse(url);
  String ext = path.extension(uri.path);
  if (ext == '.svg') {
    return svg_provider.Svg.network(url);
  } else {
    return CachedNetworkImageProvider(url);
  }
}