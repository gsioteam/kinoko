
import '../core/core.dart';
import '../core/callback.dart';
import '../core/array.dart';

class Context extends Base {
  static reg() {
    Base.reg(Context, "gs::Context", Base)
    ..constructor = ((id)=>Context().setID(id));
  }
  
  bool isReady() => call("isReady");
  void reload([Map data]) => call("reload", argv: [data]);
  void loadMore() => call("loadMore");
  void enterView() => call("enterView");
  void exitView() => call("exitView");

  static const int DataReload = 1;
  static const int DataAppend = 2;

  Callback _on_data_changed;
  set on_data_changed(Callback cb) {
    r(_on_data_changed);
    _on_data_changed = cb == null ? null : cb.control();
    call("setOnDataChanged", argv: [cb]);
  }

  Callback _on_loading_status;
  set on_loading_status(Callback cb) {
    r(_on_loading_status);
    _on_loading_status = cb == null ? null : cb.control();
    call("setOnLoadingStatus", argv: [cb]);
  }

  Callback _on_error;
  set on_error(Callback cb) {
    r(_on_error);
    _on_error = cb == null ? null : cb.control();
    call("setOnError", argv: [cb]);
  }

  Callback _on_reload_complete;
  set on_reload_complete(Callback cb) {
    r(_on_reload_complete);
    _on_reload_complete = cb == null ? null : cb.control();
    call("setOnReloadComplete", argv: [cb]);
  }

  Array get data => call("getData");
  dynamic get info_data => call("getInfoData");
  set info_data(dynamic data) => call("setInfoData", argv: [data]);

  String get projectKey => call("getProjectKey");

  static Array searchKeys(String key, int limit) => Base.s_call(Context, "searchKeys", argv: [key, limit]);
  static void removeSearchKey(String key) => Base.s_call(Context, "removeSearchKey", argv: [key]);

  @override
  void destroy() {
    r(_on_data_changed);
    r(_on_loading_status);
    r(_on_error);
    super.destroy();
  }

  dynamic getSetting(String key) => call("getSetting", argv: [key]);
  void setSetting(String key, dynamic value) => call("setSetting", argv: [key, value]);
}

class LibraryContext extends Base {
  static void reg() {
    Base.reg(LibraryContext, "gs::LibraryContext", Base);
  }

  LibraryContext.allocate() {
    super.allocate([]);
  }

  Array get data => call("getData");

  bool parseLibrary(String str) => call("parseLibrary", argv: [str]);
  bool insertLibrary(String url) => call("insertLibrary", argv: [url]);
}