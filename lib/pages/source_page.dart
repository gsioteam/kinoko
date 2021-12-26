
import 'package:flutter/material.dart';
import 'package:browser_webview/browser_webview.dart';
import '../localizations/localizations.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;

class SourcePage extends StatefulWidget {
  final String url;

  SourcePage({
    Key? key,
    required this.url
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => SourcePageState();

}

class SourcePageState extends State<SourcePage> {
  late BrowserWebViewController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kt("source")),
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_new),
            onPressed: () async {
              UrlLauncher.launch(controller.url.value);
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
            child: BrowserWebView(
              controller: controller,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    controller = BrowserWebViewController(
      initializeUrl: widget.url,
    );
  }
}