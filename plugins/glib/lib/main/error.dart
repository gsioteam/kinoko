
import '../core/core.dart';

class Error extends Base {
  static reg() {
    Base.reg(Error, "gs::Error", Base)
    ..constructor = (id)=>Error().setID(id);
  }

  int get code => call("getCode");
  set code(int v) => call("setCode", argv: [v]);

  String get msg => call("getMsg");
  set msg(String v) => call("setMsg", argv: [v]);
}