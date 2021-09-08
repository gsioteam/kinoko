
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

void enterFullscreen() {
  SystemChrome.setEnabledSystemUIOverlays([
  ]);
}

void exitFullscreen() {
  SystemChrome.setEnabledSystemUIOverlays([
    SystemUiOverlay.top,
    SystemUiOverlay.bottom,
  ]);
}

void enterFullscreenMode() {
  FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_LAYOUT_NO_LIMITS);
}

void exitFullscreenMode() {
  FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_LAYOUT_NO_LIMITS);
  exitFullscreen();
}