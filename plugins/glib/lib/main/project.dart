
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

  Project.allocate(path) {
    super.allocate([path]);
  }

  get isValidated => call("isValidated");
  get name => call("getName");
  get subtitle => call("getSubtitle");
  get url => call("getUrl");
  get index => call("getIndex");
  get book => call("getBook");
  Array get categories => call("getCategories");
  get fullpath => call("getFullpath");
  get path => call("getPath");

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
}