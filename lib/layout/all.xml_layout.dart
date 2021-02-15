import 'package:xml_layout/xml_layout.dart';
import 'package:xml_layout/register.dart';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/src/material/material_button.dart';
import 'package:flutter/src/foundation/basic_types.dart';
import 'package:flutter/src/rendering/mouse_cursor.dart';
import 'package:flutter/src/material/button_theme.dart';
import 'dart:ui';
import 'package:flutter/src/painting/edge_insets.dart';
import 'package:flutter/src/material/theme_data.dart';
import 'package:flutter/src/painting/borders.dart';
import 'package:flutter/src/widgets/focus_manager.dart';
import 'dart:core';
import 'package:flutter/src/services/raw_keyboard.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/src/rendering/flex.dart';
import 'package:flutter/src/painting/basic_types.dart';
import 'package:flutter/src/material/scaffold.dart';
import 'package:flutter/src/widgets/preferred_size.dart';
import 'package:flutter/src/material/floating_action_button_location.dart';
import 'package:flutter/src/gestures/recognizer.dart';
import 'package:flutter/src/widgets/text.dart';
import 'package:flutter/src/painting/text_style.dart';
import 'package:flutter/src/painting/strut_style.dart';
import 'package:flutter/src/rendering/paragraph.dart';
import 'package:flutter/src/painting/text_painter.dart';
import 'package:flutter/src/painting/inline_span.dart';
import 'package:flutter/src/widgets/icon.dart';
import 'package:flutter/src/widgets/icon_data.dart';
import 'package:flutter/src/widgets/scroll_view.dart';
import 'package:flutter/src/widgets/scroll_controller.dart';
import 'package:flutter/src/widgets/scroll_physics.dart';
import 'package:flutter/src/rendering/sliver_grid.dart';
import 'package:flutter/src/widgets/sliver.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/painting/alignment.dart';
import 'package:flutter/src/painting/decoration.dart';
import 'package:flutter/src/rendering/box.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:typed_data';
import 'package:flutter/src/material/app_bar.dart';
import 'package:flutter/src/widgets/icon_theme_data.dart';
import 'package:flutter/src/material/text_theme.dart';
import 'package:flutter/src/widgets/image.dart';
import 'package:flutter/src/painting/image_provider.dart';
import 'package:flutter/src/painting/image_stream.dart';
import 'package:flutter/src/painting/box_fit.dart';
import 'package:flutter/src/painting/decoration_image.dart';
import 'dart:io';
import 'package:flutter/src/services/asset_bundle.dart';

Register register = Register(() {
  XmlLayout.register("MaterialButton", (node, key) {
    return MaterialButton(
        key: key,
        onPressed: node.s<void Function()>("onPressed"),
        onLongPress: node.s<void Function()>("onLongPress"),
        onHighlightChanged: node.s<void Function(bool)>("onHighlightChanged"),
        mouseCursor: node.s<MouseCursor>("mouseCursor"),
        textTheme: node.s<ButtonTextTheme>("textTheme"),
        textColor: node.s<Color>("textColor"),
        disabledTextColor: node.s<Color>("disabledTextColor"),
        color: node.s<Color>("color"),
        disabledColor: node.s<Color>("disabledColor"),
        focusColor: node.s<Color>("focusColor"),
        hoverColor: node.s<Color>("hoverColor"),
        highlightColor: node.s<Color>("highlightColor"),
        splashColor: node.s<Color>("splashColor"),
        colorBrightness: node.s<Brightness>("colorBrightness"),
        elevation: node.s<double>("elevation"),
        focusElevation: node.s<double>("focusElevation"),
        hoverElevation: node.s<double>("hoverElevation"),
        highlightElevation: node.s<double>("highlightElevation"),
        disabledElevation: node.s<double>("disabledElevation"),
        padding: node.s<EdgeInsetsGeometry>("padding"),
        visualDensity: node.s<VisualDensity>("visualDensity"),
        shape: node.s<ShapeBorder>("shape"),
        clipBehavior: node.s<Clip>("clipBehavior", Clip.none),
        focusNode: node.s<FocusNode>("focusNode"),
        autofocus: node.s<bool>("autofocus", false),
        materialTapTargetSize:
            node.s<MaterialTapTargetSize>("materialTapTargetSize"),
        animationDuration: node.s<Duration>("animationDuration"),
        minWidth: node.s<double>("minWidth"),
        height: node.s<double>("height"),
        enableFeedback: node.s<bool>("enableFeedback", true),
        child: node.child<Widget>());
  });
  XmlLayout.registerInline(MouseCursor, "defer", true, (node, method) {
    return MouseCursor.defer;
  });
  XmlLayout.registerInline(MouseCursor, "uncontrolled", true, (node, method) {
    return MouseCursor.uncontrolled;
  });
  XmlLayout.registerEnum(ButtonTextTheme.values);
  XmlLayout.registerInline(Color, "", false, (node, method) {
    return Color(int.tryParse(method[0]));
  });
  XmlLayout.registerInline(Color, "fromARGB", false, (node, method) {
    return Color.fromARGB(int.tryParse(method[0]), int.tryParse(method[1]),
        int.tryParse(method[2]), int.tryParse(method[3]));
  });
  XmlLayout.registerInline(Color, "fromRGBO", false, (node, method) {
    return Color.fromRGBO(int.tryParse(method[0]), int.tryParse(method[1]),
        int.tryParse(method[2]), double.tryParse(method[3]));
  });
  XmlLayout.registerEnum(Brightness.values);
  XmlLayout.registerInline(EdgeInsetsGeometry, "infinity", true,
      (node, method) {
    return EdgeInsetsGeometry.infinity;
  });
  XmlLayout.register("VisualDensity", (node, key) {
    return VisualDensity(
        horizontal: node.s<double>("horizontal", 0.0),
        vertical: node.s<double>("vertical", 0.0));
  });
  XmlLayout.registerInline(VisualDensity, "standard", true, (node, method) {
    return VisualDensity.standard;
  });
  XmlLayout.registerInline(VisualDensity, "comfortable", true, (node, method) {
    return VisualDensity.comfortable;
  });
  XmlLayout.registerInline(VisualDensity, "compact", true, (node, method) {
    return VisualDensity.compact;
  });
  XmlLayout.registerInline(VisualDensity, "adaptivePlatformDensity", true,
      (node, method) {
    return VisualDensity.adaptivePlatformDensity;
  });
  XmlLayout.registerEnum(Clip.values);
  XmlLayout.register("FocusNode", (node, key) {
    return FocusNode(
        debugLabel: node.s<String>("debugLabel"),
        onKey: node.s<bool Function(FocusNode, RawKeyEvent)>("onKey"),
        skipTraversal: node.s<bool>("skipTraversal", false),
        canRequestFocus: node.s<bool>("canRequestFocus", true),
        descendantsAreFocusable: node.s<bool>("descendantsAreFocusable", true));
  });
  XmlLayout.registerEnum(MaterialTapTargetSize.values);
  XmlLayout.register("Duration", (node, key) {
    return Duration(
        days: node.s<int>("days"),
        hours: node.s<int>("hours"),
        minutes: node.s<int>("minutes"),
        seconds: node.s<int>("seconds"),
        milliseconds: node.s<int>("milliseconds"),
        microseconds: node.s<int>("microseconds"));
  });
  XmlLayout.registerInline(Duration, "zero", true, (node, method) {
    return Duration.zero;
  });
  XmlLayout.register("Column", (node, key) {
    return Column(
        key: key,
        mainAxisAlignment: node.s<MainAxisAlignment>(
            "mainAxisAlignment", MainAxisAlignment.start),
        mainAxisSize: node.s<MainAxisSize>("mainAxisSize", MainAxisSize.max),
        crossAxisAlignment: node.s<CrossAxisAlignment>(
            "crossAxisAlignment", CrossAxisAlignment.center),
        textDirection: node.s<TextDirection>("textDirection"),
        verticalDirection: node.s<VerticalDirection>(
            "verticalDirection", VerticalDirection.down),
        textBaseline: node.s<TextBaseline>("textBaseline"),
        children: node.children<Widget>());
  });
  XmlLayout.registerEnum(MainAxisAlignment.values);
  XmlLayout.registerEnum(MainAxisSize.values);
  XmlLayout.registerEnum(CrossAxisAlignment.values);
  XmlLayout.registerEnum(TextDirection.values);
  XmlLayout.registerEnum(VerticalDirection.values);
  XmlLayout.registerEnum(TextBaseline.values);
  XmlLayout.register("Scaffold", (node, key) {
    return Scaffold(
        key: key,
        appBar: node.s<PreferredSizeWidget>("appBar"),
        body: node.s<Widget>("body"),
        floatingActionButton: node.s<Widget>("floatingActionButton"),
        floatingActionButtonLocation: node
            .s<FloatingActionButtonLocation>("floatingActionButtonLocation"),
        floatingActionButtonAnimator: node
            .s<FloatingActionButtonAnimator>("floatingActionButtonAnimator"),
        persistentFooterButtons: node.array<Widget>("persistentFooterButtons"),
        drawer: node.s<Widget>("drawer"),
        endDrawer: node.s<Widget>("endDrawer"),
        bottomNavigationBar: node.s<Widget>("bottomNavigationBar"),
        bottomSheet: node.s<Widget>("bottomSheet"),
        backgroundColor: node.s<Color>("backgroundColor"),
        resizeToAvoidBottomPadding: node.s<bool>("resizeToAvoidBottomPadding"),
        resizeToAvoidBottomInset: node.s<bool>("resizeToAvoidBottomInset"),
        primary: node.s<bool>("primary", true),
        drawerDragStartBehavior: node.s<DragStartBehavior>(
            "drawerDragStartBehavior", DragStartBehavior.start),
        extendBody: node.s<bool>("extendBody", false),
        extendBodyBehindAppBar: node.s<bool>("extendBodyBehindAppBar", false),
        drawerScrimColor: node.s<Color>("drawerScrimColor"),
        drawerEdgeDragWidth: node.s<double>("drawerEdgeDragWidth"),
        drawerEnableOpenDragGesture:
            node.s<bool>("drawerEnableOpenDragGesture", true),
        endDrawerEnableOpenDragGesture:
            node.s<bool>("endDrawerEnableOpenDragGesture", true));
  });
  XmlLayout.registerInline(FloatingActionButtonLocation, "startTop", true,
      (node, method) {
    return FloatingActionButtonLocation.startTop;
  });
  XmlLayout.registerInline(FloatingActionButtonLocation, "miniStartTop", true,
      (node, method) {
    return FloatingActionButtonLocation.miniStartTop;
  });
  XmlLayout.registerInline(FloatingActionButtonLocation, "centerTop", true,
      (node, method) {
    return FloatingActionButtonLocation.centerTop;
  });
  XmlLayout.registerInline(FloatingActionButtonLocation, "miniCenterTop", true,
      (node, method) {
    return FloatingActionButtonLocation.miniCenterTop;
  });
  XmlLayout.registerInline(FloatingActionButtonLocation, "endTop", true,
      (node, method) {
    return FloatingActionButtonLocation.endTop;
  });
  XmlLayout.registerInline(FloatingActionButtonLocation, "miniEndTop", true,
      (node, method) {
    return FloatingActionButtonLocation.miniEndTop;
  });
  XmlLayout.registerInline(FloatingActionButtonLocation, "startFloat", true,
      (node, method) {
    return FloatingActionButtonLocation.startFloat;
  });
  XmlLayout.registerInline(FloatingActionButtonLocation, "miniStartFloat", true,
      (node, method) {
    return FloatingActionButtonLocation.miniStartFloat;
  });
  XmlLayout.registerInline(FloatingActionButtonLocation, "centerFloat", true,
      (node, method) {
    return FloatingActionButtonLocation.centerFloat;
  });
  XmlLayout.registerInline(
      FloatingActionButtonLocation, "miniCenterFloat", true, (node, method) {
    return FloatingActionButtonLocation.miniCenterFloat;
  });
  XmlLayout.registerInline(FloatingActionButtonLocation, "endFloat", true,
      (node, method) {
    return FloatingActionButtonLocation.endFloat;
  });
  XmlLayout.registerInline(FloatingActionButtonLocation, "miniEndFloat", true,
      (node, method) {
    return FloatingActionButtonLocation.miniEndFloat;
  });
  XmlLayout.registerInline(FloatingActionButtonLocation, "startDocked", true,
      (node, method) {
    return FloatingActionButtonLocation.startDocked;
  });
  XmlLayout.registerInline(
      FloatingActionButtonLocation, "miniStartDocked", true, (node, method) {
    return FloatingActionButtonLocation.miniStartDocked;
  });
  XmlLayout.registerInline(FloatingActionButtonLocation, "centerDocked", true,
      (node, method) {
    return FloatingActionButtonLocation.centerDocked;
  });
  XmlLayout.registerInline(
      FloatingActionButtonLocation, "miniCenterDocked", true, (node, method) {
    return FloatingActionButtonLocation.miniCenterDocked;
  });
  XmlLayout.registerInline(FloatingActionButtonLocation, "endDocked", true,
      (node, method) {
    return FloatingActionButtonLocation.endDocked;
  });
  XmlLayout.registerInline(FloatingActionButtonLocation, "miniEndDocked", true,
      (node, method) {
    return FloatingActionButtonLocation.miniEndDocked;
  });
  XmlLayout.registerInline(FloatingActionButtonAnimator, "scaling", true,
      (node, method) {
    return FloatingActionButtonAnimator.scaling;
  });
  XmlLayout.registerEnum(DragStartBehavior.values);
  XmlLayout.register("Text", (node, key) {
    return Text(node.s<String>("arg:0") ?? node.t<String>(),
        key: key,
        style: node.s<TextStyle>("style"),
        strutStyle: node.s<StrutStyle>("strutStyle"),
        textAlign: node.s<TextAlign>("textAlign"),
        textDirection: node.s<TextDirection>("textDirection"),
        locale: node.s<Locale>("locale"),
        softWrap: node.s<bool>("softWrap"),
        overflow: node.s<TextOverflow>("overflow"),
        textScaleFactor: node.s<double>("textScaleFactor"),
        maxLines: node.s<int>("maxLines"),
        semanticsLabel: node.s<String>("semanticsLabel"),
        textWidthBasis: node.s<TextWidthBasis>("textWidthBasis"),
        textHeightBehavior: node.s<TextHeightBehavior>("textHeightBehavior"));
  });
  XmlLayout.register("Text.rich", (node, key) {
    return Text.rich(node.s<InlineSpan>("arg:0") ?? node.child<InlineSpan>(),
        key: key,
        style: node.s<TextStyle>("style"),
        strutStyle: node.s<StrutStyle>("strutStyle"),
        textAlign: node.s<TextAlign>("textAlign"),
        textDirection: node.s<TextDirection>("textDirection"),
        locale: node.s<Locale>("locale"),
        softWrap: node.s<bool>("softWrap"),
        overflow: node.s<TextOverflow>("overflow"),
        textScaleFactor: node.s<double>("textScaleFactor"),
        maxLines: node.s<int>("maxLines"),
        semanticsLabel: node.s<String>("semanticsLabel"),
        textWidthBasis: node.s<TextWidthBasis>("textWidthBasis"),
        textHeightBehavior: node.s<TextHeightBehavior>("textHeightBehavior"));
  });
  XmlLayout.register("TextStyle", (node, key) {
    return TextStyle(
        inherit: node.s<bool>("inherit", true),
        color: node.s<Color>("color"),
        backgroundColor: node.s<Color>("backgroundColor"),
        fontSize: node.s<double>("fontSize"),
        fontWeight: node.s<FontWeight>("fontWeight"),
        fontStyle: node.s<FontStyle>("fontStyle"),
        letterSpacing: node.s<double>("letterSpacing"),
        wordSpacing: node.s<double>("wordSpacing"),
        textBaseline: node.s<TextBaseline>("textBaseline"),
        height: node.s<double>("height"),
        locale: node.s<Locale>("locale"),
        foreground: node.s<Paint>("foreground"),
        background: node.s<Paint>("background"),
        shadows: node.array<Shadow>("shadows"),
        fontFeatures: node.array<FontFeature>("fontFeatures"),
        decoration: node.s<TextDecoration>("decoration"),
        decorationColor: node.s<Color>("decorationColor"),
        decorationStyle: node.s<TextDecorationStyle>("decorationStyle"),
        decorationThickness: node.s<double>("decorationThickness"),
        debugLabel: node.s<String>("debugLabel"),
        fontFamily: node.s<String>("fontFamily"),
        fontFamilyFallback: node.array<String>("fontFamilyFallback"),
        package: node.s<String>("package"));
  });
  XmlLayout.registerInline(FontWeight, "w100", true, (node, method) {
    return FontWeight.w100;
  });
  XmlLayout.registerInline(FontWeight, "w200", true, (node, method) {
    return FontWeight.w200;
  });
  XmlLayout.registerInline(FontWeight, "w300", true, (node, method) {
    return FontWeight.w300;
  });
  XmlLayout.registerInline(FontWeight, "w400", true, (node, method) {
    return FontWeight.w400;
  });
  XmlLayout.registerInline(FontWeight, "w500", true, (node, method) {
    return FontWeight.w500;
  });
  XmlLayout.registerInline(FontWeight, "w600", true, (node, method) {
    return FontWeight.w600;
  });
  XmlLayout.registerInline(FontWeight, "w700", true, (node, method) {
    return FontWeight.w700;
  });
  XmlLayout.registerInline(FontWeight, "w800", true, (node, method) {
    return FontWeight.w800;
  });
  XmlLayout.registerInline(FontWeight, "w900", true, (node, method) {
    return FontWeight.w900;
  });
  XmlLayout.registerInline(FontWeight, "normal", true, (node, method) {
    return FontWeight.normal;
  });
  XmlLayout.registerInline(FontWeight, "bold", true, (node, method) {
    return FontWeight.bold;
  });
  XmlLayout.registerEnum(FontStyle.values);
  XmlLayout.registerInline(Locale, "", false, (node, method) {
    return Locale(jsonDecode(method[0]), jsonDecode(method[1]));
  });
  XmlLayout.register("Locale.fromSubtags", (node, key) {
    return Locale.fromSubtags(
        languageCode: node.s<String>("languageCode"),
        scriptCode: node.s<String>("scriptCode"),
        countryCode: node.s<String>("countryCode"));
  });
  XmlLayout.register("TextDecoration.combine", (node, key) {
    return TextDecoration.combine(node.s<List<TextDecoration>>("arg:0") ??
        node.child<List<TextDecoration>>());
  });
  XmlLayout.registerInline(TextDecoration, "none", true, (node, method) {
    return TextDecoration.none;
  });
  XmlLayout.registerInline(TextDecoration, "underline", true, (node, method) {
    return TextDecoration.underline;
  });
  XmlLayout.registerInline(TextDecoration, "overline", true, (node, method) {
    return TextDecoration.overline;
  });
  XmlLayout.registerInline(TextDecoration, "lineThrough", true, (node, method) {
    return TextDecoration.lineThrough;
  });
  XmlLayout.registerEnum(TextDecorationStyle.values);
  XmlLayout.register("StrutStyle", (node, key) {
    return StrutStyle(
        fontFamily: node.s<String>("fontFamily"),
        fontFamilyFallback: node.array<String>("fontFamilyFallback"),
        fontSize: node.s<double>("fontSize"),
        height: node.s<double>("height"),
        leading: node.s<double>("leading"),
        fontWeight: node.s<FontWeight>("fontWeight"),
        fontStyle: node.s<FontStyle>("fontStyle"),
        forceStrutHeight: node.s<bool>("forceStrutHeight"),
        debugLabel: node.s<String>("debugLabel"),
        package: node.s<String>("package"));
  });
  XmlLayout.register("StrutStyle.fromTextStyle", (node, key) {
    return StrutStyle.fromTextStyle(
        node.s<TextStyle>("arg:0") ?? node.child<TextStyle>(),
        fontFamily: node.s<String>("fontFamily"),
        fontFamilyFallback: node.array<String>("fontFamilyFallback"),
        fontSize: node.s<double>("fontSize"),
        height: node.s<double>("height"),
        leading: node.s<double>("leading"),
        fontWeight: node.s<FontWeight>("fontWeight"),
        fontStyle: node.s<FontStyle>("fontStyle"),
        forceStrutHeight: node.s<bool>("forceStrutHeight"),
        debugLabel: node.s<String>("debugLabel"),
        package: node.s<String>("package"));
  });
  XmlLayout.registerInline(StrutStyle, "disabled", true, (node, method) {
    return StrutStyle.disabled;
  });
  XmlLayout.registerEnum(TextAlign.values);
  XmlLayout.registerEnum(TextOverflow.values);
  XmlLayout.registerEnum(TextWidthBasis.values);
  XmlLayout.register("TextHeightBehavior", (node, key) {
    return TextHeightBehavior(
        applyHeightToFirstAscent: node.s<bool>("applyHeightToFirstAscent"),
        applyHeightToLastDescent: node.s<bool>("applyHeightToLastDescent"));
  });
  XmlLayout.registerInline(TextHeightBehavior, "fromEncoded", false,
      (node, method) {
    return TextHeightBehavior.fromEncoded(int.tryParse(method[0]));
  });
  XmlLayout.register("Icon", (node, key) {
    return Icon(node.s<IconData>("arg:0") ?? node.child<IconData>(),
        key: key,
        size: node.s<double>("size"),
        color: node.s<Color>("color"),
        semanticLabel: node.s<String>("semanticLabel"),
        textDirection: node.s<TextDirection>("textDirection"));
  });
  XmlLayout.register("GridView", (node, key) {
    return GridView(
        key: key,
        scrollDirection: node.s<Axis>("scrollDirection", Axis.vertical),
        reverse: node.s<bool>("reverse", false),
        controller: node.s<ScrollController>("controller"),
        primary: node.s<bool>("primary"),
        physics: node.s<ScrollPhysics>("physics"),
        shrinkWrap: node.s<bool>("shrinkWrap", false),
        padding: node.s<EdgeInsetsGeometry>("padding"),
        gridDelegate: node.s<SliverGridDelegate>("gridDelegate"),
        addAutomaticKeepAlives: node.s<bool>("addAutomaticKeepAlives", true),
        addRepaintBoundaries: node.s<bool>("addRepaintBoundaries", true),
        addSemanticIndexes: node.s<bool>("addSemanticIndexes", true),
        cacheExtent: node.s<double>("cacheExtent"),
        children: node.children<Widget>(),
        semanticChildCount: node.s<int>("semanticChildCount"),
        dragStartBehavior: node.s<DragStartBehavior>(
            "dragStartBehavior", DragStartBehavior.start),
        clipBehavior: node.s<Clip>("clipBehavior", Clip.hardEdge),
        keyboardDismissBehavior: node.s<ScrollViewKeyboardDismissBehavior>(
            "keyboardDismissBehavior",
            ScrollViewKeyboardDismissBehavior.manual),
        restorationId: node.s<String>("restorationId"));
  });
  XmlLayout.register("GridView.builder", (node, key) {
    return GridView.builder(
        key: key,
        scrollDirection: node.s<Axis>("scrollDirection", Axis.vertical),
        reverse: node.s<bool>("reverse", false),
        controller: node.s<ScrollController>("controller"),
        primary: node.s<bool>("primary"),
        physics: node.s<ScrollPhysics>("physics"),
        shrinkWrap: node.s<bool>("shrinkWrap", false),
        padding: node.s<EdgeInsetsGeometry>("padding"),
        gridDelegate: node.s<SliverGridDelegate>("gridDelegate"),
        itemBuilder: node.s<Widget Function(BuildContext, int)>("itemBuilder"),
        itemCount: node.s<int>("itemCount"),
        addAutomaticKeepAlives: node.s<bool>("addAutomaticKeepAlives", true),
        addRepaintBoundaries: node.s<bool>("addRepaintBoundaries", true),
        addSemanticIndexes: node.s<bool>("addSemanticIndexes", true),
        cacheExtent: node.s<double>("cacheExtent"),
        semanticChildCount: node.s<int>("semanticChildCount"),
        dragStartBehavior: node.s<DragStartBehavior>(
            "dragStartBehavior", DragStartBehavior.start),
        keyboardDismissBehavior: node.s<ScrollViewKeyboardDismissBehavior>(
            "keyboardDismissBehavior",
            ScrollViewKeyboardDismissBehavior.manual),
        restorationId: node.s<String>("restorationId"),
        clipBehavior: node.s<Clip>("clipBehavior", Clip.hardEdge));
  });
  XmlLayout.register("GridView.custom", (node, key) {
    return GridView.custom(
        key: key,
        scrollDirection: node.s<Axis>("scrollDirection", Axis.vertical),
        reverse: node.s<bool>("reverse", false),
        controller: node.s<ScrollController>("controller"),
        primary: node.s<bool>("primary"),
        physics: node.s<ScrollPhysics>("physics"),
        shrinkWrap: node.s<bool>("shrinkWrap", false),
        padding: node.s<EdgeInsetsGeometry>("padding"),
        gridDelegate: node.s<SliverGridDelegate>("gridDelegate"),
        childrenDelegate: node.s<SliverChildDelegate>("childrenDelegate"),
        cacheExtent: node.s<double>("cacheExtent"),
        semanticChildCount: node.s<int>("semanticChildCount"),
        dragStartBehavior: node.s<DragStartBehavior>(
            "dragStartBehavior", DragStartBehavior.start),
        keyboardDismissBehavior: node.s<ScrollViewKeyboardDismissBehavior>(
            "keyboardDismissBehavior",
            ScrollViewKeyboardDismissBehavior.manual),
        restorationId: node.s<String>("restorationId"),
        clipBehavior: node.s<Clip>("clipBehavior", Clip.hardEdge));
  });
  XmlLayout.register("GridView.count", (node, key) {
    return GridView.count(
        key: key,
        scrollDirection: node.s<Axis>("scrollDirection", Axis.vertical),
        reverse: node.s<bool>("reverse", false),
        controller: node.s<ScrollController>("controller"),
        primary: node.s<bool>("primary"),
        physics: node.s<ScrollPhysics>("physics"),
        shrinkWrap: node.s<bool>("shrinkWrap", false),
        padding: node.s<EdgeInsetsGeometry>("padding"),
        crossAxisCount: node.s<int>("crossAxisCount"),
        mainAxisSpacing: node.s<double>("mainAxisSpacing", 0.0),
        crossAxisSpacing: node.s<double>("crossAxisSpacing", 0.0),
        childAspectRatio: node.s<double>("childAspectRatio", 1.0),
        addAutomaticKeepAlives: node.s<bool>("addAutomaticKeepAlives", true),
        addRepaintBoundaries: node.s<bool>("addRepaintBoundaries", true),
        addSemanticIndexes: node.s<bool>("addSemanticIndexes", true),
        cacheExtent: node.s<double>("cacheExtent"),
        children: node.children<Widget>(),
        semanticChildCount: node.s<int>("semanticChildCount"),
        dragStartBehavior: node.s<DragStartBehavior>(
            "dragStartBehavior", DragStartBehavior.start),
        keyboardDismissBehavior: node.s<ScrollViewKeyboardDismissBehavior>(
            "keyboardDismissBehavior",
            ScrollViewKeyboardDismissBehavior.manual),
        restorationId: node.s<String>("restorationId"),
        clipBehavior: node.s<Clip>("clipBehavior", Clip.hardEdge));
  });
  XmlLayout.register("GridView.extent", (node, key) {
    return GridView.extent(
        key: key,
        scrollDirection: node.s<Axis>("scrollDirection", Axis.vertical),
        reverse: node.s<bool>("reverse", false),
        controller: node.s<ScrollController>("controller"),
        primary: node.s<bool>("primary"),
        physics: node.s<ScrollPhysics>("physics"),
        shrinkWrap: node.s<bool>("shrinkWrap", false),
        padding: node.s<EdgeInsetsGeometry>("padding"),
        maxCrossAxisExtent: node.s<double>("maxCrossAxisExtent"),
        mainAxisSpacing: node.s<double>("mainAxisSpacing", 0.0),
        crossAxisSpacing: node.s<double>("crossAxisSpacing", 0.0),
        childAspectRatio: node.s<double>("childAspectRatio", 1.0),
        addAutomaticKeepAlives: node.s<bool>("addAutomaticKeepAlives", true),
        addRepaintBoundaries: node.s<bool>("addRepaintBoundaries", true),
        addSemanticIndexes: node.s<bool>("addSemanticIndexes", true),
        cacheExtent: node.s<double>("cacheExtent"),
        children: node.children<Widget>(),
        semanticChildCount: node.s<int>("semanticChildCount"),
        dragStartBehavior: node.s<DragStartBehavior>(
            "dragStartBehavior", DragStartBehavior.start),
        keyboardDismissBehavior: node.s<ScrollViewKeyboardDismissBehavior>(
            "keyboardDismissBehavior",
            ScrollViewKeyboardDismissBehavior.manual),
        restorationId: node.s<String>("restorationId"),
        clipBehavior: node.s<Clip>("clipBehavior", Clip.hardEdge));
  });
  XmlLayout.registerEnum(Axis.values);
  XmlLayout.register("ScrollController", (node, key) {
    return ScrollController(
        initialScrollOffset: node.s<double>("initialScrollOffset", 0.0),
        keepScrollOffset: node.s<bool>("keepScrollOffset", true),
        debugLabel: node.s<String>("debugLabel"));
  });
  XmlLayout.register("ScrollPhysics", (node, key) {
    return ScrollPhysics(parent: node.s<ScrollPhysics>("parent"));
  });
  XmlLayout.registerEnum(ScrollViewKeyboardDismissBehavior.values);
  XmlLayout.register("Container", (node, key) {
    return Container(
        key: key,
        alignment: node.s<AlignmentGeometry>("alignment"),
        padding: node.s<EdgeInsetsGeometry>("padding"),
        color: node.s<Color>("color"),
        decoration: node.s<Decoration>("decoration"),
        foregroundDecoration: node.s<Decoration>("foregroundDecoration"),
        width: node.s<double>("width"),
        height: node.s<double>("height"),
        constraints: node.s<BoxConstraints>("constraints"),
        margin: node.s<EdgeInsetsGeometry>("margin"),
        transform: node.s<Matrix4>("transform"),
        child: node.child<Widget>(),
        clipBehavior: node.s<Clip>("clipBehavior", Clip.none));
  });
  XmlLayout.register("BoxConstraints", (node, key) {
    return BoxConstraints(
        minWidth: node.s<double>("minWidth", 0.0),
        maxWidth: node.s<double>("maxWidth", double.infinity),
        minHeight: node.s<double>("minHeight", 0.0),
        maxHeight: node.s<double>("maxHeight", double.infinity));
  });
  XmlLayout.registerInline(BoxConstraints, "tight", false, (node, method) {
    return BoxConstraints.tight(node.v<Size>(method[0]));
  });
  XmlLayout.register("BoxConstraints.tightFor", (node, key) {
    return BoxConstraints.tightFor(
        width: node.s<double>("width"), height: node.s<double>("height"));
  });
  XmlLayout.register("BoxConstraints.tightForFinite", (node, key) {
    return BoxConstraints.tightForFinite(
        width: node.s<double>("width", double.infinity),
        height: node.s<double>("height", double.infinity));
  });
  XmlLayout.registerInline(BoxConstraints, "loose", false, (node, method) {
    return BoxConstraints.loose(node.v<Size>(method[0]));
  });
  XmlLayout.register("BoxConstraints.expand", (node, key) {
    return BoxConstraints.expand(
        width: node.s<double>("width"), height: node.s<double>("height"));
  });
  XmlLayout.registerInline(Matrix4, "", false, (node, method) {
    return Matrix4(
        double.tryParse(method[0]),
        double.tryParse(method[1]),
        double.tryParse(method[2]),
        double.tryParse(method[3]),
        double.tryParse(method[4]),
        double.tryParse(method[5]),
        double.tryParse(method[6]),
        double.tryParse(method[7]),
        double.tryParse(method[8]),
        double.tryParse(method[9]),
        double.tryParse(method[10]),
        double.tryParse(method[11]),
        double.tryParse(method[12]),
        double.tryParse(method[13]),
        double.tryParse(method[14]),
        double.tryParse(method[15]));
  });
  XmlLayout.register("Matrix4.fromList", (node, key) {
    return Matrix4.fromList(
        node.s<List<double>>("arg:0") ?? node.child<List<double>>());
  });
  XmlLayout.registerInline(Matrix4, "zero", false, (node, method) {
    return Matrix4.zero();
  });
  XmlLayout.registerInline(Matrix4, "identity", false, (node, method) {
    return Matrix4.identity();
  });
  XmlLayout.registerInline(Matrix4, "copy", false, (node, method) {
    return Matrix4.copy(node.v<Matrix4>(method[0]));
  });
  XmlLayout.registerInline(Matrix4, "inverted", false, (node, method) {
    return Matrix4.inverted(node.v<Matrix4>(method[0]));
  });
  XmlLayout.registerInline(Matrix4, "columns", false, (node, method) {
    return Matrix4.columns(
        node.v<Vector4>(method[0]),
        node.v<Vector4>(method[1]),
        node.v<Vector4>(method[2]),
        node.v<Vector4>(method[3]));
  });
  XmlLayout.registerInline(Matrix4, "outer", false, (node, method) {
    return Matrix4.outer(
        node.v<Vector4>(method[0]), node.v<Vector4>(method[1]));
  });
  XmlLayout.registerInline(Matrix4, "rotationX", false, (node, method) {
    return Matrix4.rotationX(double.tryParse(method[0]));
  });
  XmlLayout.registerInline(Matrix4, "rotationY", false, (node, method) {
    return Matrix4.rotationY(double.tryParse(method[0]));
  });
  XmlLayout.registerInline(Matrix4, "rotationZ", false, (node, method) {
    return Matrix4.rotationZ(double.tryParse(method[0]));
  });
  XmlLayout.registerInline(Matrix4, "translation", false, (node, method) {
    return Matrix4.translation(node.v<Vector3>(method[0]));
  });
  XmlLayout.registerInline(Matrix4, "translationValues", false, (node, method) {
    return Matrix4.translationValues(double.tryParse(method[0]),
        double.tryParse(method[1]), double.tryParse(method[2]));
  });
  XmlLayout.registerInline(Matrix4, "diagonal3", false, (node, method) {
    return Matrix4.diagonal3(node.v<Vector3>(method[0]));
  });
  XmlLayout.registerInline(Matrix4, "diagonal3Values", false, (node, method) {
    return Matrix4.diagonal3Values(double.tryParse(method[0]),
        double.tryParse(method[1]), double.tryParse(method[2]));
  });
  XmlLayout.registerInline(Matrix4, "skewX", false, (node, method) {
    return Matrix4.skewX(double.tryParse(method[0]));
  });
  XmlLayout.registerInline(Matrix4, "skewY", false, (node, method) {
    return Matrix4.skewY(double.tryParse(method[0]));
  });
  XmlLayout.registerInline(Matrix4, "skew", false, (node, method) {
    return Matrix4.skew(double.tryParse(method[0]), double.tryParse(method[1]));
  });
  XmlLayout.registerInline(Matrix4, "fromFloat64List", false, (node, method) {
    return Matrix4.fromFloat64List(node.v<Float64List>(method[0]));
  });
  XmlLayout.register("Matrix4.fromBuffer", (node, key) {
    return Matrix4.fromBuffer(
        node.s<ByteBuffer>("arg:0"), node.s<int>("arg:1"));
  });
  XmlLayout.registerInline(Matrix4, "compose", false, (node, method) {
    return Matrix4.compose(node.v<Vector3>(method[0]),
        node.v<Quaternion>(method[1]), node.v<Vector3>(method[2]));
  });
  XmlLayout.register("AppBar", (node, key) {
    return AppBar(
        key: key,
        leading: node.s<Widget>("leading"),
        automaticallyImplyLeading:
            node.s<bool>("automaticallyImplyLeading", true),
        title: node.s<Widget>("title"),
        actions: node.array<Widget>("actions"),
        flexibleSpace: node.s<Widget>("flexibleSpace"),
        bottom: node.s<PreferredSizeWidget>("bottom"),
        elevation: node.s<double>("elevation"),
        shadowColor: node.s<Color>("shadowColor"),
        shape: node.s<ShapeBorder>("shape"),
        backgroundColor: node.s<Color>("backgroundColor"),
        brightness: node.s<Brightness>("brightness"),
        iconTheme: node.s<IconThemeData>("iconTheme"),
        actionsIconTheme: node.s<IconThemeData>("actionsIconTheme"),
        textTheme: node.s<TextTheme>("textTheme"),
        primary: node.s<bool>("primary", true),
        centerTitle: node.s<bool>("centerTitle"),
        excludeHeaderSemantics: node.s<bool>("excludeHeaderSemantics", false),
        titleSpacing:
            node.s<double>("titleSpacing", NavigationToolbar.kMiddleSpacing),
        toolbarOpacity: node.s<double>("toolbarOpacity", 1.0),
        bottomOpacity: node.s<double>("bottomOpacity", 1.0),
        toolbarHeight: node.s<double>("toolbarHeight"),
        leadingWidth: node.s<double>("leadingWidth"));
  });
  XmlLayout.register("IconThemeData", (node, key) {
    return IconThemeData(
        color: node.s<Color>("color"),
        opacity: node.s<double>("opacity"),
        size: node.s<double>("size"));
  });
  XmlLayout.registerInline(IconThemeData, "fallback", false, (node, method) {
    return IconThemeData.fallback();
  });
  XmlLayout.register("TextTheme", (node, key) {
    return TextTheme(
        headline1: node.s<TextStyle>("headline1"),
        headline2: node.s<TextStyle>("headline2"),
        headline3: node.s<TextStyle>("headline3"),
        headline4: node.s<TextStyle>("headline4"),
        headline5: node.s<TextStyle>("headline5"),
        headline6: node.s<TextStyle>("headline6"),
        subtitle1: node.s<TextStyle>("subtitle1"),
        subtitle2: node.s<TextStyle>("subtitle2"),
        bodyText1: node.s<TextStyle>("bodyText1"),
        bodyText2: node.s<TextStyle>("bodyText2"),
        caption: node.s<TextStyle>("caption"),
        button: node.s<TextStyle>("button"),
        overline: node.s<TextStyle>("overline"),
        display4: node.s<TextStyle>("display4"),
        display3: node.s<TextStyle>("display3"),
        display2: node.s<TextStyle>("display2"),
        display1: node.s<TextStyle>("display1"),
        headline: node.s<TextStyle>("headline"),
        title: node.s<TextStyle>("title"),
        subhead: node.s<TextStyle>("subhead"),
        subtitle: node.s<TextStyle>("subtitle"),
        body2: node.s<TextStyle>("body2"),
        body1: node.s<TextStyle>("body1"));
  });
  XmlLayout.register("Image", (node, key) {
    return Image(
        key: key,
        image: node.s<ImageProvider<Object>>("image"),
        frameBuilder: node.s<Widget Function(BuildContext, Widget, int, bool)>(
            "frameBuilder"),
        loadingBuilder:
            node.s<Widget Function(BuildContext, Widget, ImageChunkEvent)>(
                "loadingBuilder"),
        errorBuilder: node.s<Widget Function(BuildContext, Object, StackTrace)>(
            "errorBuilder"),
        semanticLabel: node.s<String>("semanticLabel"),
        excludeFromSemantics: node.s<bool>("excludeFromSemantics", false),
        width: node.s<double>("width"),
        height: node.s<double>("height"),
        color: node.s<Color>("color"),
        colorBlendMode: node.s<BlendMode>("colorBlendMode"),
        fit: node.s<BoxFit>("fit"),
        alignment: node.s<AlignmentGeometry>("alignment", Alignment.center),
        repeat: node.s<ImageRepeat>("repeat", ImageRepeat.noRepeat),
        centerSlice: node.s<Rect>("centerSlice"),
        matchTextDirection: node.s<bool>("matchTextDirection", false),
        gaplessPlayback: node.s<bool>("gaplessPlayback", false),
        isAntiAlias: node.s<bool>("isAntiAlias", false),
        filterQuality:
            node.s<FilterQuality>("filterQuality", FilterQuality.low));
  });
  XmlLayout.register("Image.network", (node, key) {
    return Image.network(node.s<String>("arg:0") ?? node.t<String>(),
        key: key,
        scale: node.s<double>("scale", 1.0),
        frameBuilder: node.s<Widget Function(BuildContext, Widget, int, bool)>(
            "frameBuilder"),
        loadingBuilder:
            node.s<Widget Function(BuildContext, Widget, ImageChunkEvent)>(
                "loadingBuilder"),
        errorBuilder: node.s<Widget Function(BuildContext, Object, StackTrace)>(
            "errorBuilder"),
        semanticLabel: node.s<String>("semanticLabel"),
        excludeFromSemantics: node.s<bool>("excludeFromSemantics", false),
        width: node.s<double>("width"),
        height: node.s<double>("height"),
        color: node.s<Color>("color"),
        colorBlendMode: node.s<BlendMode>("colorBlendMode"),
        fit: node.s<BoxFit>("fit"),
        alignment: node.s<AlignmentGeometry>("alignment", Alignment.center),
        repeat: node.s<ImageRepeat>("repeat", ImageRepeat.noRepeat),
        centerSlice: node.s<Rect>("centerSlice"),
        matchTextDirection: node.s<bool>("matchTextDirection", false),
        gaplessPlayback: node.s<bool>("gaplessPlayback", false),
        filterQuality:
            node.s<FilterQuality>("filterQuality", FilterQuality.low),
        isAntiAlias: node.s<bool>("isAntiAlias", false),
        headers: node.s<Map<String, String>>("headers"),
        cacheWidth: node.s<int>("cacheWidth"),
        cacheHeight: node.s<int>("cacheHeight"));
  });
  XmlLayout.register("Image.file", (node, key) {
    return Image.file(node.s<File>("arg:0") ?? node.child<File>(),
        key: key,
        scale: node.s<double>("scale", 1.0),
        frameBuilder: node.s<Widget Function(BuildContext, Widget, int, bool)>(
            "frameBuilder"),
        errorBuilder: node.s<Widget Function(BuildContext, Object, StackTrace)>(
            "errorBuilder"),
        semanticLabel: node.s<String>("semanticLabel"),
        excludeFromSemantics: node.s<bool>("excludeFromSemantics", false),
        width: node.s<double>("width"),
        height: node.s<double>("height"),
        color: node.s<Color>("color"),
        colorBlendMode: node.s<BlendMode>("colorBlendMode"),
        fit: node.s<BoxFit>("fit"),
        alignment: node.s<AlignmentGeometry>("alignment", Alignment.center),
        repeat: node.s<ImageRepeat>("repeat", ImageRepeat.noRepeat),
        centerSlice: node.s<Rect>("centerSlice"),
        matchTextDirection: node.s<bool>("matchTextDirection", false),
        gaplessPlayback: node.s<bool>("gaplessPlayback", false),
        isAntiAlias: node.s<bool>("isAntiAlias", false),
        filterQuality:
            node.s<FilterQuality>("filterQuality", FilterQuality.low),
        cacheWidth: node.s<int>("cacheWidth"),
        cacheHeight: node.s<int>("cacheHeight"));
  });
  XmlLayout.register("Image.asset", (node, key) {
    return Image.asset(node.s<String>("arg:0") ?? node.t<String>(),
        key: key,
        bundle: node.s<AssetBundle>("bundle"),
        frameBuilder: node.s<Widget Function(BuildContext, Widget, int, bool)>(
            "frameBuilder"),
        errorBuilder: node.s<Widget Function(BuildContext, Object, StackTrace)>(
            "errorBuilder"),
        semanticLabel: node.s<String>("semanticLabel"),
        excludeFromSemantics: node.s<bool>("excludeFromSemantics", false),
        scale: node.s<double>("scale"),
        width: node.s<double>("width"),
        height: node.s<double>("height"),
        color: node.s<Color>("color"),
        colorBlendMode: node.s<BlendMode>("colorBlendMode"),
        fit: node.s<BoxFit>("fit"),
        alignment: node.s<AlignmentGeometry>("alignment", Alignment.center),
        repeat: node.s<ImageRepeat>("repeat", ImageRepeat.noRepeat),
        centerSlice: node.s<Rect>("centerSlice"),
        matchTextDirection: node.s<bool>("matchTextDirection", false),
        gaplessPlayback: node.s<bool>("gaplessPlayback", false),
        isAntiAlias: node.s<bool>("isAntiAlias", false),
        package: node.s<String>("package"),
        filterQuality:
            node.s<FilterQuality>("filterQuality", FilterQuality.low),
        cacheWidth: node.s<int>("cacheWidth"),
        cacheHeight: node.s<int>("cacheHeight"));
  });
  XmlLayout.register("Image.memory", (node, key) {
    return Image.memory(node.s<Uint8List>("arg:0") ?? node.child<Uint8List>(),
        key: key,
        scale: node.s<double>("scale", 1.0),
        frameBuilder: node.s<Widget Function(BuildContext, Widget, int, bool)>(
            "frameBuilder"),
        errorBuilder: node.s<Widget Function(BuildContext, Object, StackTrace)>(
            "errorBuilder"),
        semanticLabel: node.s<String>("semanticLabel"),
        excludeFromSemantics: node.s<bool>("excludeFromSemantics", false),
        width: node.s<double>("width"),
        height: node.s<double>("height"),
        color: node.s<Color>("color"),
        colorBlendMode: node.s<BlendMode>("colorBlendMode"),
        fit: node.s<BoxFit>("fit"),
        alignment: node.s<AlignmentGeometry>("alignment", Alignment.center),
        repeat: node.s<ImageRepeat>("repeat", ImageRepeat.noRepeat),
        centerSlice: node.s<Rect>("centerSlice"),
        matchTextDirection: node.s<bool>("matchTextDirection", false),
        gaplessPlayback: node.s<bool>("gaplessPlayback", false),
        isAntiAlias: node.s<bool>("isAntiAlias", false),
        filterQuality:
            node.s<FilterQuality>("filterQuality", FilterQuality.low),
        cacheWidth: node.s<int>("cacheWidth"),
        cacheHeight: node.s<int>("cacheHeight"));
  });
  XmlLayout.registerEnum(BlendMode.values);
  XmlLayout.registerEnum(BoxFit.values);
  XmlLayout.registerEnum(ImageRepeat.values);
  XmlLayout.registerInline(Rect, "fromLTRB", false, (node, method) {
    return Rect.fromLTRB(double.tryParse(method[0]), double.tryParse(method[1]),
        double.tryParse(method[2]), double.tryParse(method[3]));
  });
  XmlLayout.registerInline(Rect, "fromLTWH", false, (node, method) {
    return Rect.fromLTWH(double.tryParse(method[0]), double.tryParse(method[1]),
        double.tryParse(method[2]), double.tryParse(method[3]));
  });
  XmlLayout.register("Rect.fromCircle", (node, key) {
    return Rect.fromCircle(
        center: node.s<Offset>("center"), radius: node.s<double>("radius"));
  });
  XmlLayout.register("Rect.fromCenter", (node, key) {
    return Rect.fromCenter(
        center: node.s<Offset>("center"),
        width: node.s<double>("width"),
        height: node.s<double>("height"));
  });
  XmlLayout.registerInline(Rect, "fromPoints", false, (node, method) {
    return Rect.fromPoints(
        node.v<Offset>(method[0]), node.v<Offset>(method[1]));
  });
  XmlLayout.registerInline(Rect, "zero", true, (node, method) {
    return Rect.zero;
  });
  XmlLayout.registerInline(Rect, "largest", true, (node, method) {
    return Rect.largest;
  });
  XmlLayout.registerInline(Offset, "", false, (node, method) {
    return Offset(double.tryParse(method[0]), double.tryParse(method[1]));
  });
  XmlLayout.registerInline(Offset, "fromDirection", false, (node, method) {
    return Offset.fromDirection(
        double.tryParse(method[0]), double.tryParse(method[1]));
  });
  XmlLayout.registerInline(Offset, "zero", true, (node, method) {
    return Offset.zero;
  });
  XmlLayout.registerInline(Offset, "infinite", true, (node, method) {
    return Offset.infinite;
  });
  XmlLayout.registerEnum(FilterQuality.values);
});
