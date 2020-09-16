
import '../core/core.dart';
import '../core/array.dart';
import 'context.dart';
import 'data_item.dart';

class Project extends Base {
  static reg() {
    Base.reg(Project, "gs::Project", Base)
      ..constructor = ((id) => Project().setID(id));
  }

  Project();

  Project.allocate(String path) {
    super.allocate([path]);
  }

  bool get isValidated => call("isValidated");
  String get name => call("getName");
  String get subtitle => call("getSubtitle");
  String get url => call("getUrl");
  String get index => call("getIndex");
  String get book => call("getBook");
  String get search => call("getSearch");
  Array get categories => call("getCategories");
  String get fullpath => call("getFullpath");
  String get path => call("getPath");
  String get settings_path => call("getSettingsPath");
  String get icon => call("getIcon");

  static Project getMainProject() => Base.s_call(Project, "getMainProject");
  void setMainProject() => call("setMainProject");

  static Project current;
  static void setCurrent(Project project) {
    r(current);
    current = project;
    current.control();
  }

  Context createIndexContext(dynamic data) => call("createIndexContext", argv: [data]);
  Context createBookContext(DataItem data) => call("createBookContext", argv: [data]);
  Context createChapterContext(DataItem data) => call("createChapterContext", argv: [data]);
  Context createSearchContext() => call("createSearchContext");
  Context createSettingsContext() => call("createSettingsContext");
}