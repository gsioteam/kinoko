import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glib/glib.dart';

void main() {
  const MethodChannel channel = MethodChannel('glib');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(Glib.setup(""), '42');
  });
}
