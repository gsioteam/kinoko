
import '../core/core.dart';
import '../core/array.dart';

class GitLibrary extends Base {
  static reg() {
    Base.reg(GitLibrary, "gs::GitLibrary", Base)
    ..constructor = ((ptr)=>GitLibrary().setID(ptr)) ;
  }

  static Array allLibraries() => Base.s_call(GitLibrary, "allLibraries");

  String get url => call("getUrl");
  void set url(String v) => call("setUrl", argv:[v]);

  int get date => call("getDate");
  void set date(int v) => call("setDate", argv:[v]);

  static bool insertLibrary(String url) => Base.s_call(GitLibrary, "insertLibrary");
}

class KeyValue extends Base {
  static reg() {
    Base.reg(KeyValue, "gs::KeyValue", Base);
  }

  static void set(String key, String value) => Base.s_call(KeyValue, "set", argv: [key, value]);
  static String get(String key) => Base.s_call(KeyValue, "get", argv: [key]);
}