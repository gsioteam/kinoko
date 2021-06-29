import 'dart:ui';

import 'package:flutter/material.dart';
import '../book_page.dart';
import '../widgets/web_image.dart';
import '../widgets/better_refresh_indicator.dart';

const List<String> imports = [
  'package:flutter/cupertino.dart'
];

const Map<String, String> converts = {
  "package:vector_math/src/vector_math_64/": "package:vector_math/vector_math_64.dart",
  "package:vector_math/src/vector_math/": "package:vector_math/vector_math.dart",
};

const Map<Type, Type> convertTypes = {
  EdgeInsetsGeometry: EdgeInsets,
  AlignmentGeometry: Alignment,
};

const List<Type> types = [
  MaterialButton,
  Column,
  Scaffold,
  Text,
  Icon,
  GridView,
  Container,
  MaterialButton,
  AppBar,
  Image,
  ListView,
  WebImage,
  BetterRefreshIndicator,
  Divider,
  ListTile,
  Row,
  Padding,
  TextButton,
  IconButton,
  CustomScrollView,
  PreferredSize,
  BarItem,
  BackdropFilter,
  ImageFilter,
  BoxDecoration,
  SliverToBoxAdapter,
  SliverGrid,
  Expanded,
  BoxShadow,
  TextSpan,
  WidgetSpan,
];