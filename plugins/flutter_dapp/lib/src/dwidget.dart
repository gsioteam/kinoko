

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:js_script/js_script.dart';
import 'package:path/path.dart' as path;
import 'package:xml_layout/xml_layout.dart';
import 'js_wrap.dart';
import 'dapp_state.dart';
import 'controller.dart';

typedef ControllerBuilder = dynamic Function(JsScript script, DWidgetState state);

class _InheritedContext extends InheritedWidget {
  final DWidgetState data;

  _InheritedContext({
    Key? key,
    required Widget child,
    required this.data,
  }) : super(
    key: key,
    child: child
  );

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    if (oldWidget is _InheritedContext) {
      return oldWidget.data != data;
    }
    return true;
  }

}

class DWidget extends StatefulWidget {
  final String file;
  final JsScript script;
  final dynamic initializeData;
  final ControllerBuilder controllerBuilder;

  DWidget({
    Key? key,
    required this.script,
    required this.file,
    this.initializeData,
    required this.controllerBuilder,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => DWidgetState();

  static DWidgetState? of(BuildContext context) {
    _InheritedContext? res = context.dependOnInheritedWidgetOfExactType<_InheritedContext>();
    return res?.data;
  }
}

class DWidgetState extends DAppState<DWidget> {

  late String template;
  late JsValue controller;
  late String file;
  GlobalKey<XmlLayoutState> _layoutKey = GlobalKey();
  bool _ready = false;

  JsScript get script => widget.script;

  DWidgetState() {
    registerMethod("getController", () {
      return controller;
    });
  }

  void updateData(VoidCallback callback) {
    if (_ready) {
      setState(callback);
    } else {
      callback();
    }
  }

  @override
  void initState() {
    super.initState();
    file = path.join(path.dirname(widget.file), "${path.basenameWithoutExtension(widget.file)}.xml");

    template = widget.script.fileSystems.loadCode(file)!;
    file = path.extension(widget.file).isEmpty ? "${widget.file}.js" : widget.file;
    JsValue jsClass = widget.script.run(file);
    if (!jsClass.isConstructor) {
      throw Exception("Script result must be a constructor.");
    }
    controller = widget.script.bind(
        widget.controllerBuilder(script, this),
        classFunc: jsClass)..retain();
    try {
      controller.invoke("load", [widget.initializeData ?? {}]);
    } catch (e) {
      print("[$runtimeType] $e");
    }

    _ready = true;
  }

  @override
  void dispose() {
    super.dispose();
    _ready = false;
    try {
      controller.invoke("unload");
    } catch (e) {
      print(e);
    }
    controller.release();
    data?.release();
  }

  JsValue? data;
  @override
  Widget build(BuildContext context) {
    data?.release();
    data = (controller["data"] as JsValue?);
    Map objects;
    if (data != null) {
      data!.retain();
      objects = DataMap(data!);
    } else {
      objects = {};
    }
    return _InheritedContext(
      child: XmlLayout(
        key: _layoutKey,
        template: template,
        objects: objects,
        onUnkownElement: (node, key) {
          print("Unkown tag ${node.name}");
        },
      ),
      data: this,
    );
  }

  String relativePath(String src) => path.normalize(path.join(file, '..', src));

  Future navigateTo(String src, {
    JsValue? data,
  }) {
    return Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return DWidget(
        file: relativePath(src),
        script: widget.script,
        initializeData: data,
        controllerBuilder: widget.controllerBuilder,
      );
    }));
  }

  navigateBack(result) {
    Navigator.of(context).pop(result);
  }

  ControllerBuilder get controllerBuilder => widget.controllerBuilder;

  State? find(String key) {
    return _layoutKey.currentState?.find(key)?.currentState;
  }
}