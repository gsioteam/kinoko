
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:glib/main/models.dart';
import 'package:glib/main/project.dart';
import 'core/binds.dart';
import 'package:path_provider/path_provider.dart' as platform;

import 'core/callback.dart';

import 'core/core.dart';
import 'core/array.dart';
import 'core/gmap.dart';
import 'core/data.dart';
import 'main/project.dart';
import 'main/context.dart';
import 'main/data_item.dart';
import 'main/error.dart';
import 'utils/git_repository.dart';
import 'utils/platform.dart';
import 'utils/bit64.dart';
import 'utils/script_context.dart';
import 'main/collection_data.dart';
import 'main/setting_item.dart';

class Glib {
  static late MethodChannel channel;
  static bool _isStatic = false;

  static setup(String root_path) async {
    if (_isStatic) return;
    _isStatic = true;
    channel = MethodChannel("glib");
    channel.setMethodCallHandler(onMethod);

    Base.reg(Base, "gc::Object", Base).constructor = (ptr) => Base().setID(ptr);
    Platform.reg();
    Array.reg();
    GMap.reg();
    Callback.reg();
    GitRepository.reg();
    GitAction.reg();
    GitRepository.reg();
    GitLibrary.reg();
    Project.reg();
    Bit64.reg();
    Context.reg();
    DataItem.reg();
    Data.reg();
    BufferData.reg();
    Error.reg();
    KeyValue.reg();
    ScriptContext.reg();
    CollectionData.reg();
    LibraryContext.reg();
    SettingItem.reg();

    Pointer<Utf8> pstr = root_path.toNativeUtf8();
    postSetup(pstr);
    malloc.free(pstr);

    File file = File(root_path + '/cacert.pem');
    if (!file.existsSync()) {
      ByteData data = await rootBundle.load("packages/glib/res/cacert.pem");
      file.writeAsBytesSync(data.buffer.asUint8List());
    }
    pstr = file.path.toNativeUtf8();
    setCacertPath(pstr);
    malloc.free(pstr);
  }

  static destroy() {
    Platform.clearPlatform();
    destroyLibrary();
    Base.setuped = false;

  }

  static Future<dynamic> onMethod(MethodCall call) async {
    switch (call.method) {
      case "sendSignal": {
        runOnMainThread();
        break;
      }
    }
  }
}


bool tokenVerify(String token, String url, String prev, Uint8List pubKey) {
  Pointer<Utf8> tokenPointer = token.toNativeUtf8();
  Pointer<Utf8> urlPointer = url.toNativeUtf8();
  Pointer<Utf8> prevPointer = prev.toNativeUtf8();
  int pubKeyLength = pubKey.lengthInBytes;
  Pointer<Uint8> pubKeyPointer = malloc.allocate(pubKeyLength);
  pubKeyPointer.asTypedList(pubKeyLength).setRange(0, pubKeyLength, pubKey);

  bool ret = dartTokenVerify(tokenPointer, urlPointer, prevPointer, pubKeyPointer, pubKeyLength) != 0;

  malloc.free(tokenPointer);
  malloc.free(urlPointer);
  malloc.free(prevPointer);
  malloc.free(pubKeyPointer);

  return ret;
}