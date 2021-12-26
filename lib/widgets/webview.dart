
import 'package:browser_webview/browser_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dapp/src/dapp_state.dart';
import 'package:kinoko/utils/plugin/utils.dart';

typedef WebViewUrlCallback = void Function(String url);
typedef WebViewErrorCallback = void Function(String url, String error);
typedef WebViewMessageCallback = void Function(dynamic data);

class WebView extends StatefulWidget {

  final String? url;
  final WebViewUrlCallback? onLoadStart;
  final WebViewUrlCallback? onLoadEnd;
  final WebViewErrorCallback? onFail;
  final WebViewMessageCallback? onMessage;
  final List? replacements;

  WebView({
    Key? key,
    this.url,
    this.onLoadStart,
    this.onLoadEnd,
    this.onFail,
    this.onMessage,
    this.replacements,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WebViewState();
}

class _WebViewState extends DAppState<WebView> {

  late BrowserWebViewController controller;

  _WebViewState() {
    registerMethod("eval", (String script) {
      return controller.eval(script);
    });
    registerMethod("getCookies", (String url) async {
      var cookies = await BrowserWebViewController.getCookies(url);
      Map<String, List<String>> retults = {};
      for (var cookie in cookies) {
        List<String>? list = retults[cookie.name];
        if (list == null) {
          list = retults[cookie.name] = [];
        }
        list.add(cookie.value);
      }
      return retults;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BrowserWebView(controller: controller);
  }

  @override
  void initState() {
    super.initState();

    List<ResourceReplacement>? replacements;
    if (widget.replacements != null) {
      replacements = [];
      for (var replacement in widget.replacements!) {
        replacements.add(ResourceReplacement(
          replacement["test"],
          replacement["resource"],
          replacement["mimeType"],
        ));
      }
    }
    controller = BrowserWebViewController(
      initializeUrl: widget.url,
      resourceReplacements: replacements,
    );
    controller.addEventHandler("message", (data) {
      if (widget.onMessage != null)
        widget.onMessage?.call(data);
    });
    controller.onLoadStart.addListener(_loadStart);
    controller.onLoadEnd.addListener(_loadEnd);
    controller.onLoadError.addListener(_loadError);
  }

  @override
  void dispose() {
    super.dispose();

    controller.onLoadStart.removeListener(_loadStart);
    controller.onLoadEnd.removeListener(_loadEnd);
    controller.onLoadError.removeListener(_loadError);
    controller.dispose();
  }

  void _loadStart() {
    widget.onLoadStart?.call(controller.onLoadStart.value);
  }

  void _loadEnd() {
    widget.onLoadEnd?.call(controller.onLoadEnd.value);
  }

  void _loadError() {
    var val = controller.onLoadError.value;
    widget.onFail?.call(val.first, val.second);
  }
}