
import '../core/core.dart';
import '../core/callback.dart';
import '../core/array.dart';

class Context extends Base {
  static reg() {
    Base.reg(Context, "gs::Context", Base)
    ..constructor = ((id)=>Context().setID(id));
  }
  
  bool isReady() => call("isReady");
  void reload() => call("reload");
  void loadMore() => call("loadMore");
  void enterView() => call("enterView");
  void exitView() => call("exitView");

  static const int DataReload = 1;
  static const int DataAppend = 2;

  Callback _on_data_changed;
  set on_data_changed(Callback cb) {
    r(_on_data_changed);
    _on_data_changed = cb.control();
    call("setOnDataChanged", argv: [cb]);
  }

  Callback _on_loading_status;
  set on_loading_status(Callback cb) {
    r(_on_loading_status);
    _on_loading_status = cb.control();
    call("setOnLoadingStatus", argv: [cb]);
  }

  Callback _on_error;
  set on_error(Callback cb) {
    r(_on_error);
    _on_error = cb.control();
    call("setOnError", argv: [cb]);
  }

  Array get data => call("getData");
  dynamic get info_data => call("getInfoData");
  set info_data(dynamic data) => call("setInfoData", argv: [data]);

  @override
  void destroy() {
    r(_on_data_changed);
    r(_on_loading_status);
    r(_on_error);
    super.destroy();
  }
}