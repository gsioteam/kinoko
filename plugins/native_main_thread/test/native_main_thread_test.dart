import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_main_thread/native_main_thread.dart';

void main() {
  const MethodChannel channel = MethodChannel('native_main_thread');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

}
