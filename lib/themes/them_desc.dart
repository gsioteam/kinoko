
import 'package:flutter/material.dart';

abstract class ThemeDesc {
  String get title;
  ThemeData get data;

  ThemeDesc._();
  factory ThemeDesc(String title, ThemeData data) => _ThemeDesc(title, data);
}

class _ThemeDesc extends ThemeDesc {
  final String title;
  final ThemeData data;

  _ThemeDesc(this.title, this.data) : super._();
}

class _DefaultThemeDesc extends ThemeDesc {
  _DefaultThemeDesc() : super._();

  final String title = "default";
  ThemeData get data => ThemeData.light().copyWith(
    primaryColor: Colors.blue,
    shadowColor: Color(0xffeeeeee),
    scaffoldBackgroundColor: Color(0xfff2f2f2),
    appBarTheme: AppBarTheme(
        color: Colors.white,
        shadowColor: Color(0xffeeeeee),
        textTheme: TextTheme(
          headline6: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.grey,
        )
    ),
    tabBarTheme: TabBarTheme(
      labelColor: Colors.blue,
      unselectedLabelColor: Colors.grey,
    ),
  );
}

List<ThemeDesc> themes = [
  _DefaultThemeDesc(),
];