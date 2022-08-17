
import 'package:flutter/material.dart';
import 'package:glib/main/models.dart';
import 'package:kinoko/configs.dart';

enum NavigatorType {
  Normal,
  InkScreen,
}

class NavigatorConfig {
  static NavigatorType? _navigatorType;

  static NavigatorType get navigatorType {
    if (_navigatorType == null) {
      String typeStr = KeyValue.get(navigator_type_key);
      if (typeStr == "ink_screen") {
        _navigatorType = NavigatorType.InkScreen;
      } else {
        _navigatorType = NavigatorType.Normal;
      }
    }
    return _navigatorType!;
  }

  static set navigatorType(NavigatorType type) {
    if (_navigatorType != type) {
      _navigatorType = type;
      String value;
      switch (type) {
        case NavigatorType.InkScreen:
          value = "ink_screen";
          break;
        case NavigatorType.Normal:
          value = "normal";
          break;
      }
      KeyValue.set(navigator_type_key, value);
    }
  }

  static Duration get duration {
    switch (navigatorType) {
      case NavigatorType.InkScreen:
        return Duration.zero;
      case NavigatorType.Normal:
        return Duration(milliseconds: 300);
    }
  }
}

class SwitchMaterialPageRoute<T> extends MaterialPageRoute<T> {
  SwitchMaterialPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
    builder: builder,
    settings: settings,
    maintainState: maintainState,
    fullscreenDialog: fullscreenDialog,
  );

  @override
  Duration get transitionDuration {
    switch (NavigatorConfig.navigatorType) {
      case NavigatorType.Normal:
        return super.transitionDuration;
      case NavigatorType.InkScreen:
        return NavigatorConfig.duration;
    }
  }
}