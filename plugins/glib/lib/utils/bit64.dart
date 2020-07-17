
import '../core/core.dart';

class Bit64 extends Base {
  static reg() {
    Base.reg(Bit64, "gs::Bit64", Base);
  }

  static String encodeString(String str) => Base.s_call(Bit64, "encodeString", argv: [str]);
  static String decodeString(String str) => Base.s_call(Bit64, "decodeString", argv: [str]);
}