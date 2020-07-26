
import '../core/core.dart';
import '../core/array.dart';

class CollectionData extends Base {
  static void reg() {
    Base.reg(CollectionData, "gs::CollectionData", Base)
    ..constructor = (id)=>CollectionData().setID(id);
  }

  static Array all(String type) => Base.s_call(CollectionData, "all", argv: [type]);
}