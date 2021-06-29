
import '../core/core.dart';

class SettingItem extends Base {
  static const int Header = 0;
  static const int Switch = 1;
  static const int Input = 2;
  static const int Options = 3;

  static reg() {
    Base.reg(SettingItem, "gs::SettingItem", Base)
        ..constructor = ((id)=>SettingItem().setID(id));
  }

  int get type => call("getType");
  set type(int v) => call("setType", argv: [v]);

  String get title => call("getTitle");
  set title(String v) => call("setTitle", argv: [v]);

  String get name => call("getName");
  set name(String v) => call("setName");

  dynamic get defaultValue => call("getDefaultValue");
  set defaultValue(dynamic v) => call("setDefaultValue", argv: [v]);

  dynamic get data => call("getData");
  set data(dynamic v) => call("setData", argv: [v]);
}