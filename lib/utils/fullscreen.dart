
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import '../configs.dart';

void enterFullscreen() {
  SystemChrome.setEnabledSystemUIOverlays([
    SystemUiOverlay.bottom,
  ]);
}

void exitFullscreen() {
  SystemChrome.setEnabledSystemUIOverlays([
    SystemUiOverlay.top,
    SystemUiOverlay.bottom,
  ]);
}

void enterFullscreenMode(BuildContext context) {
  // FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_LAYOUT_NO_LIMITS);
  // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
  //   systemNavigationBarDividerColor: Colors.black,
  // ));
}

void exitFullscreenMode(BuildContext context) {
  var style = Theme.of(context).appBarTheme.systemOverlayStyle;
  // FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_LAYOUT_NO_LIMITS);
  SystemChrome.setSystemUIOverlayStyle(style!);
  exitFullscreen();
}