
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../localizations/localizations.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;

class SourcePage extends StatefulWidget {
  final String url;

  SourcePage({
    Key key,
    this.url
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => SourcePageState();

}

class SourcePageState extends State<SourcePage> {
  InAppWebViewController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kt("source")),
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_new),
            onPressed: () async {
              if (controller == null) {
                UrlLauncher.launch(widget.url);
              } else {
                UrlLauncher.launch((await controller.getUrl()).toString());
              }
            }
          )
        ],
      ),
      body: Column(
        children: [
          // Container(
          //   padding: EdgeInsets.only(
          //     left: 8,
          //     right: 8,
          //     top: 4,
          //     bottom: 4
          //   ),
          //   child: Text(kt('source_description')),
          // ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: Uri.parse(widget.url)
              ),
              onWebViewCreated: (controller) {
                this.controller = controller;
              },
            )
          ),
        ],
      ),
    );
  }
}