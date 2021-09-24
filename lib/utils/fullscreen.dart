
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

void enterFullscreenMode() {
  // FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_LAYOUT_NO_LIMITS);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
    systemNavigationBarDividerColor: Colors.black,
  ));
}

void exitFullscreenMode() {
  // FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_LAYOUT_NO_LIMITS);
  SystemChrome.setSystemUIOverlayStyle(defaultStyle);
  exitFullscreen();
}