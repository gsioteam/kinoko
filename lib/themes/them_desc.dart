
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  ThemeData get data {

    Color primaryColor = Color(0xff04AA6D);

    return ThemeData.light().copyWith(
      primaryColor: primaryColor,
      shadowColor: Color(0xff888888),
      scaffoldBackgroundColor: Color(0xfff2f2f2),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shadowColor: Color(0xff888888),
        textTheme: TextTheme(
          headline6: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.grey,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.white
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: primaryColor,
              width: 2,
            ),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        background: Color(0xffb0e8d3),
        onBackground: Colors.white,
      )
    );
  }
}

class _DarkThemeDesc extends ThemeDesc {
  _DarkThemeDesc() : super._();

  final String title = "dark";
  ThemeData get data {

    Color primaryColor = Color(0xff04AA6D);

    return ThemeData.dark().copyWith(
        primaryColor: primaryColor,
        // shadowColor: Color(0xff888888),
        // scaffoldBackgroundColor: Color(0xfff2f2f2),
        appBarTheme: AppBarTheme(
          color: Colors.black,
          foregroundColor: Colors.white,
          // shadowColor: Color(0xff888888),
          textTheme: TextTheme(
            headline6: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconTheme: IconThemeData(
            color: Colors.grey,
          ),
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.white
          ),
        ),
        tabBarTheme: TabBarTheme(
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicator: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: primaryColor,
                width: 2,
              ),
            ),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: primaryColor,
          backgroundColor: Colors.black,
        ),
        colorScheme: ColorScheme.dark(
          primary: primaryColor,
          background: Color(0xffb0e8d3),
          onBackground: Colors.white,
          surface: Colors.black,
        )
    );
  }
}

List<ThemeDesc> themes = [
  _DefaultThemeDesc(),
  _DarkThemeDesc(),
];