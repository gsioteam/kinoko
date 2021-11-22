
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

final DynamicLibrary nativeGLib = Platform.isAndroid
    ? DynamicLibrary.open("libflutter_git.so")
    : DynamicLibrary.process();

class CGitRepository extends Struct {
  external Pointer<Utf8> path;

  external Pointer repo;
}

class CGitController extends Struct {
  @Int32()
  external int id;

  @Int32()
  external int canceled;

  external Pointer<Utf8> arg_1;
  external Pointer<Utf8> arg_2;
  external Pointer<CGitRepository> repo;
}

void Function(Pointer<Utf8> path) flutterSetCacertPath = nativeGLib
    .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>("flutter_set_cacert_path")
    .asFunction();

void Function(Pointer<CGitController> controller) flutterClone = nativeGLib
    .lookup<NativeFunction<Void Function(Pointer<CGitController>)>>("flutter_clone")
    .asFunction();
void Function(Pointer<CGitController> controller) flutterFetch = nativeGLib
    .lookup<NativeFunction<Void Function(Pointer<CGitController>)>>("flutter_fetch")
    .asFunction();
void Function(Pointer<CGitController> controller) flutterCheckout = nativeGLib
    .lookup<NativeFunction<Void Function(Pointer<CGitController>)>>("flutter_checkout")
    .asFunction();

int Function(Pointer<CGitRepository> repo) flutterOpenRepository = nativeGLib
    .lookup<NativeFunction<Int32 Function(Pointer<CGitRepository> repo)>>("flutter_open_repository")
    .asFunction();

void Function() flutterInit = nativeGLib
    .lookup<NativeFunction<Void Function()>>("flutter_init")
    .asFunction();

void Function(Pointer<CGitRepository> repo) flutterDeleteRepository = nativeGLib
    .lookup<NativeFunction<Void Function(Pointer<CGitRepository> repo)>>("flutter_delete_repository")
    .asFunction();


Pointer<Utf8> Function(Pointer<CGitRepository> repo, Pointer<Utf8> branch) flutterGetSha1 = nativeGLib
    .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<CGitRepository>, Pointer<Utf8>)>>("flutter_get_sha1")
    .asFunction();