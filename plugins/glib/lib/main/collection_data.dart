
import '../core/core.dart';
import '../core/array.dart';

class CollectionData extends Base {
  static void reg() {
    Base.reg(CollectionData, "gs::CollectionData", Base)
    ..constructor = (id)=>CollectionData().setID(id);
  }

  static Array all(String type) => Base.s_call(CollectionData, "all", argv: [type]);
  static Array findBy(String type, String sort, int page, int count) => Base.s_call(CollectionData, "findBy", argv: [type, sort, page, count]);

  void save() => call("save");
  void remove() => call("remove");

  int get flag => call("getFlag");
  set flag(int v) => call("setFlag", argv: [v]);

  String get data => call("getData");
  void setJSONData(dynamic data) => call("setJSONData", argv: [data]);
}