
import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_git/src/ffi_bind.dart';
import 'package:native_main_thread/native_main_thread.dart';

class GitControllerValue {
  String event;
  String content;

  GitControllerValue({
    this.event = "",
    this.content = ""
  });
}

class GitController extends ValueNotifier<GitControllerValue> {
  static int _idCounter = 0xf1;

  final Completer<void> completer = Completer();
  GitRepository repo;
  late Pointer<CGitController> _controller;

  int _id;
  int get id => _id;
  bool _used = false;

  bool _disposed = false;

  GitController(this.repo) :
        _id = _idCounter++,
        super(GitControllerValue()) {
    _controller = malloc.allocate(sizeOf<CGitController>());
    _controller.ref.repo = repo._repository;
    _controller.ref.id = _id;
    _controller.ref.canceled = 0;
    NativeMainThread.instance.addListener("event:$_id", _onEvent);
    repo._lock++;
  }

  dispose() {
    super.dispose();
    _disposed = true;
    NativeMainThread.instance.removeListener("event:$_id", _onEvent);
    malloc.free(_controller);
    repo._lock--;
  }

  _onEvent(String name, String data) {
    var arr = data.split(":");
    if (arr.length == 2) {
      String event = arr[0];
      String content = arr[1];

      value = GitControllerValue(
        event: event,
        content: content,
      );

      switch (event) {
        case "complete": {
          completer.complete();
          break;
        }
        case "error": {
          completer.completeError(Exception(content));
          break;
        }
      }
    } else {
      print("Can not parse $data");
    }
  }

  void cancel() {
    if (_disposed) throw Exception("Disposed");
    _controller.ref.canceled = 1;
  }
}

class GitRepository {

  final String path;
  late Pointer<CGitRepository> _repository;
  int _lock = 0;

  GitRepository(this.path) {
    flutterInit();
    _repository = malloc.allocate(sizeOf<CGitRepository>());
    _repository.ref.path = path.toNativeUtf8();
    _repository.ref.repo = Pointer.fromAddress(0);
  }

  void dispose() {
    if (_lock != 0) throw Exception("Action is running.");
    flutterDeleteRepository(_repository);
    malloc.free(_repository.ref.path);
    malloc.free(_repository);
  }

  bool open() {
    return flutterOpenRepository(_repository) == 0;
  }

  bool get isVisible => _repository.ref.repo.address != 0;

  Future<void> clone(GitController controller, {
    required String url,
    String branch = "master",
  }) async {
    if (controller._used)
      throw Exception("The controller already be used.");
    controller._used = true;
    controller._controller.ref.arg_1 = url.toNativeUtf8();
    controller._controller.ref.arg_2 = branch.toNativeUtf8();
    flutterClone(controller._controller);

    try {
      await controller.completer.future;
    } catch (e) {
      print("[Clone] $e");
    }

    malloc.free(controller._controller.ref.arg_1);
    malloc.free(controller._controller.ref.arg_2);
  }

  Future<void> fetch(GitController controller, {
    String remote = "origin"
  }) async {
    if (controller._used)
      throw Exception("The controller already be used.");
    controller._used = true;
    controller._controller.ref.arg_1 = remote.toNativeUtf8();

    flutterFetch(controller._controller);
    try {
      await controller.completer.future;
    } catch (e) {
      print("[Fetch] $e");
    }

    malloc.free(controller._controller.ref.arg_1);
  }

  Future<void> checkout(GitController controller, {
    String branch = "master",
  }) async {
    if (controller._used)
      throw Exception("The controller already be used.");
    controller._used = true;
    controller._controller.ref.arg_1 = branch.toNativeUtf8();

    flutterCheckout(controller._controller);
    try {
      await controller.completer.future;
    } catch (e) {
      print("[Fetch] $e");
    }

    malloc.free(controller._controller.ref.arg_1);
  }

  String getSHA1(String path) {
    var ptr = path.toNativeUtf8();
    var retPtr = flutterGetSha1(_repository, ptr);
    malloc.free(ptr);
    String ret = retPtr.toDartString();
    malloc.free(retPtr);
    return ret;
  }

  static void setCacertPath(String path) {
    flutterInit();
    var ptr = path.toNativeUtf8();
    flutterSetCacertPath(ptr);
    malloc.free(ptr);
  }
}