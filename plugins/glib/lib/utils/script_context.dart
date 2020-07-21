
import '../core/core.dart';

class ScriptContext extends Base {
  static reg() {
    Base.reg(ScriptContext, "gs::ScriptContext", Base);
  }

  dynamic eval(String script) => call("eval", argv: [script]);
}