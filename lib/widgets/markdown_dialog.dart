
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownDialog extends StatelessWidget {

  final Uri uri;
  final String markdown;

  MarkdownDialog({
    Key? key,
    required this.uri,
    required this.markdown,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Markdown(
        data: markdown,
        onTapLink: (String text, String? href, String title) {
          if (href != null) {
            launch(uri.resolve(href).toString());
          }
        },
        imageBuilder: (uri, title, alt) {
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
            child: CachedNetworkImage(imageUrl: (uri.hasScheme ? uri : this.uri.resolve(uri.path)).toString()),
          );
        },
      ),
    );
  }
}