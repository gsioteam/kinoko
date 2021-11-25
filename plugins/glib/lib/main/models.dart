
import '../core/core.dart';
import '../core/array.dart';

class KeyValue extends Base {
  static reg() {
    Base.reg(KeyValue, "gs::KeyValue", Base);
  }

  static void set(String key, String value) => Base.s_call(KeyValue, "set", argv: [key, value]);
  static String get(String key) => Base.s_call(KeyValue, "get", argv: [key])??"";
}