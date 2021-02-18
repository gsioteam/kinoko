
import 'package:ffi/ffi.dart';
import 'dart:ffi';
import 'dart:io';

final DynamicLibrary nativeGLib = Platform.isAndroid
    ? DynamicLibrary.open("libglib.so")
    : DynamicLibrary.process();

const int TypeNull = 0;
const int TypeInt = 1;
const int TypeDouble = 2;
const int TypeObject = 3;
const int TypeString = 4;
const int TypeBoolean = 5;
const int TypePointer = 6;

class NativeTarget extends Struct {
  @Int8()
  int type;

  @Int64()
  int intValue;

  @Double()
  double doubleValue;

  Pointer pointerValue;

  @Uint8()
  int release;
}


void Function() runOnMainThread = nativeGLib
    .lookup<NativeFunction<Void Function()>>("dart_runOnMainThread").asFunction();

Pointer Function(Pointer<Utf8>) bindClass = nativeGLib
    .lookup<NativeFunction<Pointer Function(Pointer<Utf8>)>>("dart_bindClass")
    .asFunction();

Pointer Function(Pointer, Pointer<NativeTarget>, int) createObject = nativeGLib
    .lookup<NativeFunction<Pointer Function(Pointer, Pointer<NativeTarget>, Int32)>>("dart_createObject")
    .asFunction();

void Function(Pointer) freeObject = nativeGLib
    .lookup<NativeFunction<Void Function(Pointer)>>("dart_freeObject")
    .asFunction();

Pointer<NativeTarget> Function(Pointer, Pointer<Utf8>, Pointer<NativeTarget>, int) callObject = nativeGLib
    .lookup<NativeFunction<Pointer<NativeTarget> Function(Pointer, Pointer<Utf8>, Pointer<NativeTarget>, Int32)>>("dart_callObject")
    .asFunction();

Pointer<NativeTarget> Function(Pointer, Pointer<Utf8>, Pointer<NativeTarget>, int) callClass = nativeGLib
    .lookup<NativeFunction<Pointer<NativeTarget> Function(Pointer, Pointer<Utf8>, Pointer<NativeTarget>, Int32)>>("dart_callClass")
    .asFunction();

void Function(Pointer<NativeTarget>) freePointer = nativeGLib
    .lookup<NativeFunction<Void Function(Pointer<NativeTarget>)>>("dart_freeResult")
    .asFunction();

typedef CallHandler = Void Function(Pointer, Pointer<Utf8>, Pointer<NativeTarget>, Int32, Pointer<NativeTarget>);
typedef CreateNative = Int32 Function(Pointer type, Pointer target);

void Function(Pointer<NativeFunction<CallHandler>>, Pointer<NativeFunction<CallHandler>>, Pointer<NativeFunction<CreateNative>>) setupLibrary = nativeGLib
    .lookup<NativeFunction<Void Function(Pointer<NativeFunction<CallHandler>>, Pointer<NativeFunction<CallHandler>>, Pointer<NativeFunction<CreateNative>>)>>("dart_setupLibrary")
    .asFunction();

void Function() destroyLibrary = nativeGLib.lookup<NativeFunction<Void Function()>>("dart_destroyLibrary").asFunction();

void Function(Pointer<Utf8>) postSetup = nativeGLib.lookup<NativeFunction<Void Function(Pointer<Utf8>)>>("dart_postSetup").asFunction();

void Function(Pointer<Utf8>) setCacertPath = nativeGLib.lookup<NativeFunction<Void Function(Pointer<Utf8>)>>("dart_setCacertPath").asFunction();
