
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/foundation/diagnostics.dart';
import 'package:js_script/js_script.dart';
import 'package:xml_layout/register.dart';
import 'package:xml_layout/xml_layout.dart';
import 'package:xml_layout/types/colors.dart' as colors;
import 'package:xml_layout/types/icons.dart' as icons;
import 'package:path/path.dart' as path;

import 'dwidget.dart';
import 'utils/node_item.dart';
import 'widgets/dimage.dart';
import 'widgets/dlistview.dart';
import 'widgets/drefresh.dart';
import 'widgets/dsliver_appbar.dart';
import 'widgets/input.dart';
import 'widgets/view.dart';
import 'widgets/dappbar.dart';
import 'widgets/dbutton.dart';
import 'widgets/tab_container.dart';
import 'widgets/dgridview.dart';

typedef TestCallback = int Function();
extension DAppNodeData on NodeData {
  T? function<T extends Function>(String name) {
    var func = s(name);
    if (func is T) {
      return func;
    } else if (func is String) {
      // Only works when return type is void or dynamic.
      var fn = ([a1, a2, a3, a4, a5]) {
        return DWidget.of(context)?.controller.invoke(func, [a1,a2,a3,a4,a5]);
      };
      if (fn is T)
        return fn as T;
    }
  }
}

Register register = Register(() {
  colors.register();
  icons.register();
  XmlLayout.register("scaffold", (node, key) {
    return Scaffold(
      key: key,
      appBar: node.s<PreferredSizeWidget>("appBar"),
      body: node.child<Widget>() ?? node.s<Widget>("body"),
      floatingActionButton: node.s<Widget>("floatingActionButton"),
      drawer: node.s<Widget>("drawer"),
      endDrawer: node.s<Widget>("endDrawer"),
      bottomNavigationBar: node.s<Widget>("bottomNavigationBar"),
      bottomSheet: node.s<Widget>("bottomSheet"),
      backgroundColor: node.s<Color>("background"),
      resizeToAvoidBottomInset: node.s<bool>("resizeToAvoidBottomInset"),
    );
  });
  XmlLayout.registerEnum(MainAxisAlignment.values);
  XmlLayout.registerEnum(MainAxisSize.values);
  XmlLayout.registerEnum(CrossAxisAlignment.values);
  XmlLayout.registerEnum(VerticalDirection.values);
  XmlLayout.registerEnum(TextDirection.values);
  XmlLayout.registerEnum(TextBaseline.values);
  XmlLayout.registerEnum(BoxFit.values);
  XmlLayout.register("row", (node, key) {
    return Row(
      key: key,
      mainAxisAlignment: node.s<MainAxisAlignment>("mainAxisAlignment",
          MainAxisAlignment.start)!,
      mainAxisSize: node.s<MainAxisSize>("mainAxisSize", MainAxisSize.max)!,
      crossAxisAlignment: node.s<CrossAxisAlignment>("crossAxisAlignment",
          CrossAxisAlignment.center)!,
      verticalDirection: node.s<VerticalDirection>("verticalDirection",
          VerticalDirection.down)!,
      textDirection: node.s<TextDirection>("textDirection"),
      textBaseline: node.s<TextBaseline>("textBaseline"),
      children: node.children<Widget>(),
    );
  });
  XmlLayout.register("column", (node, key) {
    return Column(
      key: key,
      mainAxisAlignment: node.s<MainAxisAlignment>("mainAxisAlignment",
          MainAxisAlignment.start)!,
      mainAxisSize: node.s<MainAxisSize>("mainAxisSize", MainAxisSize.max)!,
      crossAxisAlignment: node.s<CrossAxisAlignment>("crossAxisAlignment",
          CrossAxisAlignment.center)!,
      verticalDirection: node.s<VerticalDirection>("verticalDirection",
          VerticalDirection.down)!,
      textDirection: node.s<TextDirection>("textDirection"),
      textBaseline: node.s<TextBaseline>("textBaseline"),
      children: node.children<Widget>(),
    );
  });
  XmlLayout.register("center", (node, key) {
    return Center(
      key: key,
      widthFactor: node.s<double>("widthFactor"),
      heightFactor: node.s<double>("heightFactor"),
      child: node.child<Widget>(),
    );
  });
  XmlLayout.registerEnum(DButtonType.values);
  XmlLayout.register("button", (node, key) {
    return DButton(
      key: key,
      child: node.child<Widget>()!,
      onPressed: node.function<VoidCallback>("onPressed"),
      onLongPress: node.function<VoidCallback>("onLongPress"),
      type: node.s<DButtonType>("type", DButtonType.elevated)!,
      minimumSize: node.s<Size>("minimumSize"),
      tapTargetSize: node.s<MaterialTapTargetSize>("tapTargetSize"),
      padding: node.s<EdgeInsets>("padding"),
      color: node.s<Color>("color"),
    );
  });
  TextStyle? getTextStyle(NodeData node) {
    TextStyle? style = node.s<TextStyle>("style");
    Color? color = node.s<Color>("color");
    double? size = node.s<double>("size");
    if (color != null || size != null) {
      if (style == null) {
        style = TextStyle(
          color: color,
          fontSize: size,
        );
      } else {
        style = style.copyWith(
          color: color,
          fontSize: size,
        );
      }
    }
    return style;
  }
  XmlLayout.register("widget", (node, key) {
    var data = DWidget.of(node.context)!;
    String file = node.s<String>("src")!;
    if (file[0] != '/') {
      file = path.join(data.file, '..', file);
    }
    return DWidget(
      key: key,
      script: data.controller.script,
      file: path.normalize(file),
      controllerBuilder: data.controllerBuilder,
      initializeData: node.s("data"),
    );
  });
  XmlLayout.registerInline(Color, "hex", false, (node, method) {
    var val = method[0];
    if (val is String) {
      if (val[0] == '#') {
        if (val.length == 4) {
          String r = val[1], g = val[2], b = val[3];
          return Color(int.parse("0xff$r$r$g$g$b$b"));
        } else if (val.length == 5) {
          String r = val[1], g = val[2], b = val[3], a = val[4];
          return Color(int.parse("0x$a$a$r$r$g$g$b$b"));
        } else if (val.length == 7) {
          return Color(int.parse("0xff${val.substring(1)}"));
        } else if (val.length == 9) {
          return Color(int.parse("0x${val.substring(7, 9)}${val.substring(1, 7)}"));
        } else {
          return Color(int.parse(val.replaceFirst('#', '0x')));
        }
      }
      return Color(int.parse(val));
    } else if (val is int) {
      return Color(val);
    }
    return null;
  });
  XmlLayout.register("AppBar", (node, key) {
    return DAppBar(
      key: key,
      child: node.child<Widget>(),
      leading: node.s<Widget>("leading"),
      actions: node.array<Widget>("actions"),
      bottom: node.s<PreferredSizeWidget>("bottom"),
      brightness: node.s<Brightness>("brightness"),
      background: node.s<Color>("background"),
      color: node.s<Color>("color"),
      height: node.s<double>("height", 56)!,
    );
  });
  XmlLayout.registerEnum(Brightness.values);
  XmlLayout.registerEnum(DragStartBehavior.values);
  XmlLayout.register("list-view", (node, key) {
    var builder = node.s<IndexedWidgetBuilder>('builder');
    if (builder == null) {
      return DListView.children(
        key: key,
        children: node.children<Widget>(),
        padding: node.s<EdgeInsets>('padding', EdgeInsets.zero)!,
      );
    } else {
      return DListView.builder(
        key: key,
        builder: builder,
        itemCount: node.s<int>('itemCount', 0)!,
        padding: node.s<EdgeInsets>('padding', EdgeInsets.zero)!,
      );
    }
  });
  XmlLayout.register("list-item", (node, key) {
    return ListTile(
      key: key,
      leading: node.s<Widget>("leading"),
      title: node.s<Widget>("title"),
      subtitle: node.s<Widget>("subtitle"),
      trailing: node.s<Widget>("trailing"),
      onTap: node.function<VoidCallback>("onTap"),
      dense: node.s<bool>("dense",),
      contentPadding: node.s<EdgeInsets>("padding"),
      tileColor: node.s<Color>("color"),
    );
  });
  var imgBuilder = (node, key) {
    Map<String, String>? headers;
    Map? map = node.s<Map>("headers");
    if (map != null) {
      headers = {};
      map.forEach((key, value) {
        if (value is String) {
          headers![key] = value;
        } else if (value is List) {
          headers![key] = value.join(',');
        }
      });
    }
    return DImage(
      key: key,
      src: node.s<String>("src")!,
      width: node.s<double>("width"),
      height: node.s<double>("height"),
      fit: node.s<BoxFit>("fit", BoxFit.contain)!,
      headers: headers,
      gaplessPlayback: node.s<bool>("gaplessPlayback", false)!,
    );
  };
  XmlLayout.register("img", imgBuilder);
  XmlLayout.register("image", imgBuilder);
  XmlLayout.register("callback", (node, key) {
    return ([a0, a1, a2, a3, a4]) {
      var data = DWidget.of(node.context);
      data!.controller.invoke(node.s<String>("function")!, node.s<List>("args", [a0, a1, a2, a3, a4])!);
    };
  });
  XmlLayout.registerInlineMethod("length", (method, status) {
    var obj = method[0];
    if (obj == null) return 0;
    else if (obj is JsValue) {
      return obj["length"];
    } else {
      return obj.length;
    }
  });
  XmlLayout.registerInlineMethod("array", (method, status) {
    List arr = [];
    for (int i = 0, t = method.length; i < t; ++i) {
      arr.add(method[i]);
    }
    return arr;
  });
  XmlLayout.register("refresh", (node, key) {
    return DRefresh(
      key: key,
      child: node.child<Widget>()!,
      loading: node.s<bool>("loading", false)!,
      onRefresh: node.function<VoidCallback>("onRefresh"),
      onLoadMore: node.function<VoidCallback>("onLoadMore"),
      refreshInset: node.s<double>("refreshInset", 36)!,
    );
  });
  XmlLayout.registerInline(EdgeInsets, "zero", true, (node, method) => EdgeInsets.zero);
  XmlLayout.registerInline(EdgeInsets, "ltrb", false, (node, method) =>
      EdgeInsets.fromLTRB(
          (method[0] as num?)?.toDouble()??0,
          (method[1] as num?)?.toDouble()??0,
          (method[2] as num?)?.toDouble()??0,
          (method[3] as num?)?.toDouble()??0)
  );
  XmlLayout.registerInline(EdgeInsets, "symmetric", false, (node, method) =>
      EdgeInsets.symmetric(
        horizontal: (method[0] as num).toDouble(),
        vertical: (method[1] as num).toDouble(),
      )
  );
  XmlLayout.registerInline(EdgeInsets, "all", false, (node, method) =>
      EdgeInsets.all((method[0] as num).toDouble())
  );
  XmlLayout.register('tabs', (node, key) {
    var items = node.children<TabItem>();
    List<Widget> tabs = [];
    List<Widget> children = [];
    for (var item in items) {
      tabs.add(Tab(
        text: item.title,
        icon: item.icon,
      ));
      children.add(item.child);
    }

    return DefaultTabController(
      key: key,
      length: children.length,
      child: Scaffold(
        appBar: TabContainer(
          tabs: tabs,
          isScrollable: node.s<bool>("scrollable", false)!,
          elevation: node.s<double>("elevation", 0)!,
        ),
        body: TabBarView(
          children: children,
        ),
        backgroundColor: node.s<Color>("background"),
      ),
    );
  });
  XmlLayout.register('tab', (node, key) {
    return TabItem(
      title: node.s<String>('title'),
      icon: node.s<Widget>('icon'),
      child: node.child<Widget>()!,
    );
  });
  XmlLayout.register('item', (node, key) {
    return NodeItem(node);
  });
  XmlLayout.register("input", (node, key) {
    return Input(
      key: key,
      placeholder: node.s<String>("placeholder"),
      text: node.s<String>("text", "")!,
      autofocus: node.s<bool>("autofocus", false)!,
      onChange: node.s<InputChangedCallback>("onChange"),
      onSubmit: node.s<InputSubmitCallback>("onSubmit"),
      onFocus: node.function<VoidCallback>("onFocus"),
      onBlur: node.function<VoidCallback>("onBlur"),
      style: node.s<TextStyle>("style"),
    );
  });
  XmlLayout.register("icon", (node, key) {
    return Icon(
      node.child<IconData>(),
      key: key,
      size: node.s<double>("size"),
      color: node.s<Color>("color"),
    );
  });
  XmlLayout.register("textstyle", (node, key) {
    return TextStyle(
      color: node.s<Color>("color"),
      backgroundColor: node.s<Color>("background"),
      fontSize: node.s<double>("size"),
    );
  });
  XmlLayout.register("stack", (node, key) {
    return Stack(
      key: key,
      alignment: node.s<Alignment>("alignment", Alignment.topLeft)!,
      children: node.children<Widget>(),
      textDirection: node.s<TextDirection>("textDirection"),
      fit: node.s<StackFit>("fit", StackFit.loose)!,
      clipBehavior: node.s<Clip>("clip", Clip.hardEdge)!,
    );
  });
  XmlLayout.registerInline(Alignment, "topLeft", true, (node, method) => Alignment.topLeft);
  XmlLayout.registerInline(Alignment, "topCenter", true, (node, method) => Alignment.topCenter);
  XmlLayout.registerInline(Alignment, "topRight", true, (node, method) => Alignment.topRight);
  XmlLayout.registerInline(Alignment, "centerLeft", true, (node, method) => Alignment.centerLeft);
  XmlLayout.registerInline(Alignment, "center", true, (node, method) => Alignment.center);
  XmlLayout.registerInline(Alignment, "centerRight", true, (node, method) => Alignment.centerRight);
  XmlLayout.registerInline(Alignment, "bottomLeft", true, (node, method) => Alignment.bottomLeft);
  XmlLayout.registerInline(Alignment, "bottomCenter", true, (node, method) => Alignment.bottomCenter);
  XmlLayout.registerInline(Alignment, "bottomRight", true, (node, method) => Alignment.bottomRight);
  XmlLayout.registerEnum(StackFit.values);
  XmlLayout.registerEnum(Clip.values);
  XmlLayout.register("view", (node, key) {
    return View(
      key: key,
      width: node.s<double>("width"),
      height: node.s<double>("height"),
      color: node.s<Color>("color"),
      child: node.child<Widget>(),
      animate: node.s<bool>("animate", false)!,
      duration: node.s<Duration>("duration", const Duration(milliseconds: 300))!,
      clip: node.s<Clip>("clip", Clip.none)!,
      border: node.s<Border>("border"),
      radius: node.s<BorderRadius>("radius"),
      gradient: node.s<Gradient>("gradient"),
      padding: node.s<EdgeInsets>("padding"),
      alignment: node.s<Alignment>("alignment"),
      margin: node.s<EdgeInsets>("margin"),
    );
  });
  XmlLayout.register("Border", (node, key) {
    return Border(
      top: node.s<BorderSide>("top", BorderSide.none)!,
      right: node.s<BorderSide>("right", BorderSide.none)!,
      bottom: node.s<BorderSide>("bottom", BorderSide.none)!,
      left: node.s<BorderSide>("left", BorderSide.none)!,
    );
  });
  XmlLayout.register("Border.all", (node, key) {
    return Border.all(
      color: node.s<Color>("color", const Color(0xFF000000))!,
      width: node.s<double>("width", 1.0)!,
      style: node.s<BorderStyle>("style", BorderStyle.none)!,
    );
  });
  XmlLayout.register("Border.symmetric", (node, key) {
    return Border.symmetric(
      vertical: node.s<BorderSide>("vertical", BorderSide.none)!,
      horizontal: node.s<BorderSide>("horizontal", BorderSide.none)!,
    );
  });
  XmlLayout.registerInline(BorderSide, "none", true, (node, method) => BorderSide.none);
  XmlLayout.registerInline(BorderSide, "solid", false, (node, method) {
    return BorderSide(
      width: (method[0] as num?)?.toDouble()??1,
      color: node.v<Color>(method[1]) ?? const Color(0xFF000000),
      style: BorderStyle.solid,
    );
  });
  XmlLayout.registerInline(BorderRadius, "all", false, (node, method) {
    return BorderRadius.circular((method[0] as num?)?.toDouble()??0);
  });
  XmlLayout.registerInline(BorderRadius, "sides", false, (node, method) {
    return BorderRadius.only(
      topLeft: Radius.circular((method[0] as num?)?.toDouble() ?? 0),
      topRight: Radius.circular((method[1] as num?)?.toDouble() ?? 0),
      bottomRight: Radius.circular((method[2] as num?)?.toDouble() ?? 0),
      bottomLeft: Radius.circular((method[3] as num?)?.toDouble() ?? 0),
    );
  });
  XmlLayout.register("LinearGradient", (node, key) {
    return LinearGradient(
      begin: node.s<Alignment>("begin", Alignment.centerRight)!,
      end: node.s<Alignment>("end", Alignment.centerRight)!,
      colors: node.array<Color>("colors")!,
      stops: node.array<double>("stops"),
      tileMode: node.s<TileMode>("mode", TileMode.clamp)!,
    );
  });
  XmlLayout.register("RadialGradient", (node, key) {
    return RadialGradient(
      center: node.s<Alignment>("center", Alignment.center)!,
      radius: node.s<double>("radius", 0.5)!,
      colors: node.array<Color>("colors")!,
      stops: node.array<double>("stops"),
      tileMode: node.s<TileMode>("mode", TileMode.clamp)!,
      focal: node.s<Alignment>("focal"),
      focalRadius: node.s<double>("focalRadius", 0)!,
    );
  });
  XmlLayout.registerEnum(BorderStyle.values);
  XmlLayout.registerInlineMethod("isNull", (method, status) {
    return method[0] == null;
  });
  XmlLayout.registerInlineMethod("isNotNull", (method, status) {
    return method[0] != null;
  });
  XmlLayout.registerInlineMethod("switch", (method, status) {
    if (method[0] == true) {
      return method[1];
    } else {
      return method[2];
    }
  });
  XmlLayout.registerEnum(Axis.values);
  XmlLayout.register("slivers", (node, key) {
    return CustomScrollView(
      key: key,
      scrollDirection: node.s<Axis>("direction", Axis.vertical)!,
      reverse: node.s<bool>("reverse", false)!,
      slivers: node.children<Widget>(),
    );
  });
  XmlLayout.register("sliver-list-view", (node, key) {
    var builder = node.s<IndexedWidgetBuilder>('builder');
    if (builder == null) {
      return DSliverListView.children(
        key: key,
        children: node.children<Widget>(),
      );
    } else {
      return DSliverListView.builder(
        key: key,
        builder: builder,
        itemCount: node.s<int>('itemCount', 0)!,
      );
    }
  });
  XmlLayout.register("sliver-appbar", (node, key) {
    return DSliverAppBar(
      key: key,
      child: node.child<Widget>(),
      leading: node.s<Widget>("leading"),
      actions: node.array<Widget>("actions"),
      bottom: node.s<PreferredSizeWidget>("bottom"),
      brightness: node.s<Brightness>("brightness"),
      background: node.s<Color>("background"),
      color: node.s<Color>("color"),
      floating: node.s<bool>("floating", false)!,
      pinned: node.s<bool>("pinned", false)!,
      expandedHeight: node.s<double>("expandedHeight"),
    );
  });
  XmlLayout.register("FlexibleSpaceBar", (node, key) {
    return FlexibleSpaceBar(
      key: key,
      title: node.child<Widget>(),
      titlePadding: node.s<EdgeInsets>("padding"),
      background: node.s<Widget>("background"),
      centerTitle: node.s<bool>("center"),
      collapseMode: node.s<CollapseMode>("mode", CollapseMode.parallax)!,
    );
  });XmlLayout.register("sliver-container", (node, key) {
    return SliverToBoxAdapter(
      key: key,
      child: node.child<Widget>(),
    );
  });
  XmlLayout.registerEnum(CollapseMode.values);

  InlineSpan makeInlineSpan(NodeData node) {
    var children = node.children();

    InlineSpan convertSpan(dynamic element) {
      if (element is Widget) {
        return WidgetSpan(
          alignment: node.s<PlaceholderAlignment>("alignment", PlaceholderAlignment.bottom)!,
          child: element,
        );
      } else if (element is InlineSpan) {
        return element;
      } else {
        return TextSpan(
          text: ""
        );
      }
    }
    if (children.isEmpty) {
      return TextSpan(
        text: node.s<String>("text") ?? node.text,
        style: getTextStyle(node),
      );
    } else if (children.length == 1) {
      return convertSpan(children[0]);
    } else {
      return TextSpan(
        children: children.map((e) => convertSpan(e)).toList(),
        style: getTextStyle(node),
      );
    }
  }

  XmlLayout.register("span", (node, key) {
    return makeInlineSpan(node);
  });
  XmlLayout.register("text", (node, key) {
    return Text.rich(
      makeInlineSpan(node),
      key: key,
      maxLines: node.s<int>("lines"),
      overflow: node.s<TextOverflow>("overflow"),
    );
  });
  XmlLayout.registerEnum(TextOverflow.values);
  XmlLayout.registerInlineMethod("infinity", (method, status) => double.infinity);
  XmlLayout.register("filter", (node, key) {
    return BackdropFilter(
      key: key,
      filter: node.s<ImageFilter>("filter")!,
      child: node.child<Widget>(),
    );
  });
  XmlLayout.registerEnum(TileMode.values);
  XmlLayout.registerInline(ImageFilter, "blur", false, (node, method) {
    return ImageFilter.blur(
      sigmaX: (method[0] as num? ?? 0).toDouble(),
      sigmaY: (method[1] as num? ?? 0).toDouble(),
      tileMode: method[2] == null ? TileMode.clamp : node.v<TileMode>(method[2], TileMode.clamp)!
    );
  });
  XmlLayout.register("color", (node, key) {
    Color? color = node.s<Color>("color");
    if (color != null) return color;
    return node.v<Color>(node.text);
  });
  XmlLayout.registerInline(Size, "", false, (node, method) {
    return Size((method[0] as num?)?.toDouble()??0, (method[1] as num?)?.toDouble()??0);
  });
  XmlLayout.registerInline(Size, "zero", true, (node, method) {
    return Size.zero;
  });
  XmlLayout.registerEnum(MaterialTapTargetSize.values);
  XmlLayout.register("PreferredSize", (node, key) {
    return PreferredSize(
      key: key,
      child: node.child<Widget>()!,
      preferredSize: node.s<Size>("size", Size.fromHeight(32))!,
    );
  });
  XmlLayout.register("Expanded", (node, key) {
    return Expanded(
      key: key,
      child: node.child<Widget>() ?? Container(),
      flex: node.s<int>("flex", 1)!,
    );
  });
  XmlLayout.register("Divider", (node, key) {
    String? type = node.s<String>("type");
    if (type == "vertical") {
      return VerticalDivider(
        key: key,
        width: node.s<double>("width"),
        thickness: node.s<double>("thickness"),
        indent: node.s<double>("indent"),
        endIndent: node.s<double>("endIndent"),
      );
    } else {
      return Divider(
        key: key,
        height: node.s<double>("height"),
        thickness: node.s<double>("thickness"),
        indent: node.s<double>("indent"),
        endIndent: node.s<double>("endIndent"),
      );
    }
  });
  XmlLayout.register("menu-button", (node, key) {
    return PopupMenuButton(
      key: key,
      child: node.child<Widget>(),
      onSelected: node.function<PopupMenuItemSelected>("onSelected"),
      onCanceled: node.function<PopupMenuCanceled>("onCanceled"),
      itemBuilder: (context) {
        return node.array<PopupMenuEntry>("items") ?? [];
      },
      padding: node.s<EdgeInsets>("padding", const EdgeInsets.all(8.0))!,
      tooltip: node.s<String>("tooltip"),
      elevation: node.s<double>("elevation"),
      icon: node.s<Widget>("icon"),
      iconSize: node.s<double>("iconSize"),
      offset: node.s<Offset>("offset", Offset.zero)!,
      enabled: node.s<bool>("enabled", true)!,
      color: node.s<Color>("color"),
    );
  });
  XmlLayout.register("menu-item", (node, key) {
    return PopupMenuItem(
      key: key,
      child: node.child<Widget>()!,
      value: node.s("value"),
      enabled: node.s<bool>("enabled", true)!,
      height: node.s<double>("height", kMinInteractiveDimension)!,
      padding: node.s<EdgeInsets>("padding"),
      textStyle: getTextStyle(node),
    );
  });
  XmlLayout.register("menu-divider", (node, key) {
    return PopupMenuDivider(
      key: key,
      height: node.s<double>("height", 16)!,
    );
  });
  XmlLayout.registerInlineMethod("js", (method, status) {
    var widget = DWidget.of(status.context);
    if (widget != null) {
      String func = method[0];
      List argv = [];
      for (var i = 1, t = method.length; i < t; ++i) {
        argv.add(method[i]);
      }
      return widget.controller.invoke(func, argv);
    }
  });
  XmlLayout.register("switch", (node, key) {
    return AnimatedSwitcher(
      duration: node.s<Duration>("duration", const Duration(milliseconds: 300))!,
      child: node.child<Widget>(),
      transitionBuilder: (child, animation) {
        return SizeTransition(
          axis: node.s<Axis>("axis", Axis.vertical)!,
          sizeFactor: animation,
          child: child,
        );
      },
    );
  });
  XmlLayout.registerEnum(Axis.values);
  XmlLayout.registerInline(Duration, "zero", true, (node, method) => Duration.zero);
  XmlLayout.registerInline(Duration, "", false, (node, method) {
    return Duration(milliseconds: (method[0] as num?)?.toInt()??0);
  });
  XmlLayout.register("grid-view", (node, key) {
    var builder = node.s<IndexedWidgetBuilder>('builder');
    if (builder == null) {
      return DGridView.children(
        key: key,
        children: node.children<Widget>(),
        padding: node.s<EdgeInsets>('padding', EdgeInsets.zero)!,
        crossAxisCount: node.s<int>("crossAxisCount", 4)!,
        childAspectRatio: node.s<double>("childAspectRatio", 1)!,
      );
    } else {
      return DGridView.builder(
        key: key,
        builder: builder,
        itemCount: node.s<int>('itemCount', 0)!,
        padding: node.s<EdgeInsets>('padding', EdgeInsets.zero)!,
        crossAxisCount: node.s<int>("crossAxisCount", 4)!,
        childAspectRatio: node.s<double>("childAspectRatio", 1)!,
      );
    }
  });
  XmlLayout.register("sliver-grid-view", (node, key) {
    var builder = node.s<IndexedWidgetBuilder>('builder');
    if (builder == null) {
      return DSliverGridView.children(
        key: key,
        children: node.children<Widget>(),
        crossAxisCount: node.s<int>("crossAxisCount", 4)!,
        childAspectRatio: node.s<double>("childAspectRatio", 1)!,
      );
    } else {
      return DSliverGridView.builder(
        key: key,
        builder: builder,
        itemCount: node.s<int>('itemCount', 0)!,
        crossAxisCount: node.s<int>("crossAxisCount", 4)!,
        childAspectRatio: node.s<double>("childAspectRatio", 1)!,
      );
    }
  });
});