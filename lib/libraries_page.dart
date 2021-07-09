
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/core/array.dart';
import 'package:glib/core/core.dart';
import 'package:glib/main/models.dart';
import 'package:crypto/crypto.dart';
import 'package:glib/utils/bit64.dart';
import 'package:glib/utils/git_repository.dart';
import 'package:glib/main/project.dart';
import 'package:kinoko/progress_dialog.dart';
import 'package:kinoko/utils/neo_cache_manager.dart';
import 'package:kinoko/utils/progress_items.dart';
import 'package:kinoko/widgets/spin_itim.dart';
import 'dart:convert';
import 'dart:io';
import 'localizations/localizations.dart';
import 'main.dart';
import 'widgets/home_widget.dart';
import 'widgets/better_refresh_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:glib/main/context.dart';
import 'utils/image_provider.dart';

const LibURL = "https://api.github.com/repos/gsioteam/env/issues/2/comments?per_page={1}&page={0}";
const int per_page = 40;

class LibraryCell extends StatefulWidget {

  final Array data;
  final int index;

  LibraryCell({Key key, this.data, this.index}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LibraryCellState();
  }
}

class _LibraryCellState extends State<LibraryCell> {

  GitLibrary library;
  GitRepository repo;
  Project project;
  String dirName;
  GlobalKey<SpinItemState> _spinKey = GlobalKey();

  _LibraryCellState();

  @override
  void initState() {
    super.initState();
    library = widget.data[widget.index].control();
    String name = Bit64.encodeString(library.url);
    project = Project.allocate(name);
    dirName = name;
    String branch = library.branch;
    repo = GitRepository.allocate(name, branch.isEmpty ? null : branch);
  }

  @override
  void dispose() {
    r(library);
    r(project);
    super.dispose();
  }

  ImageProvider getIcon() {
    String icon = library.icon;
    if (icon != null && icon.isNotEmpty) {
      return makeImageProvider(icon);
    }
    if (project.isValidated) {
      String iconpath = project.fullpath + "/icon.png";
      File icon = new File(iconpath);
      if (icon.existsSync()) {
        return FileImage(icon);
      } else if (project.icon.isNotEmpty) {
        return makeImageProvider(project.icon);
      }
    }
    return NeoImageProvider(
      uri: Uri.parse("https://www.tinygraphs.com/squares/${generateMd5(library.url)}?theme=bythepool&numcolors=3&size=180&fmt=jpg"),
      cacheManager: NeoCacheManager.defaultManager
    );
  }

  void installConfirm() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(kt("confirm")),
          content: Text(
            kt("install_confirm").replaceFirst("{url}", library.url),
            softWrap: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: (){
                Navigator.of(context).pop();
              },
              child: Text(kt("no"))
            ),
            TextButton(
              onPressed: (){
                Navigator.of(context).pop();
                install();
              },
              child: Text(kt("yes"))
            )
          ],
        );
      }
    );
  }

  void install() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
          return ProgressDialog(
            title: kt("clone_project"),
            item: GitItem.clone(repo, library.url)..cancelable=true,
          );
      }
    ).then((value) {
      setState(() {
        r(project);
        project = Project.allocate(dirName);
        if (repo.isOpen() && project.isValidated)
          selectConfirm();
      });
    });
  }

  bool selectMainProject() => project.setMainProject();
  
  void selectConfirm() {
    BuildContext mainContext = context;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(kt("confirm")),
          content: Text(kt("select_main_project")),
          actions: <Widget>[
            TextButton(
                onPressed: (){
                  Navigator.of(context).pop();
                },
                child: Text(kt("no"))
            ),
            TextButton(
                onPressed: (){
                  Navigator.of(context).pop();
                  if (selectMainProject()) {
                    AppStatusNotification().dispatch(mainContext);
                  } else {
                    Fluttertoast.showToast(msg: "Plugin version not match.");
                  }
                },
                child: Text(kt("yes"))
            )
          ],
        );
      }
    );
  }

  Widget buildUnkown(BuildContext context) {
    String title = library.title;
    if (title == null || title.isEmpty) title = library.url;
    return ListTile(
      contentPadding: EdgeInsets.fromLTRB(16, 6, 10, 6),
      title: Text(title,),
      subtitle: Text(kt("not_installed")),
      leading: Container(
        child: Image(
          image: getIcon(),
          width: 56,
          height: 56,
        ),
        decoration: BoxDecoration(
            color: Color(0x1F999999),
            borderRadius: BorderRadius.all(Radius.circular(4))
        ),
      ),
      onTap: installConfirm,
    );
  }

  Widget buildProject(BuildContext context) {
    List<InlineSpan> icons = [
      TextSpan(text: project.name),
    ];
    if (project.path == KeyValue.get("MAIN_PROJECT")) {
      icons.insert(0, WidgetSpan(child: Icon(Icons.arrow_right, color: Colors.blueAccent,)));
    }
    return ListTile(
      contentPadding: EdgeInsets.fromLTRB(16, 6, 10, 6),
      title: Text.rich(TextSpan(
        children: icons
      )),
      subtitle: Text("Ver. ${repo.localID()}"),
      leading: Container(
        child: Image(
          image: getIcon(),
          width: 56,
          height: 56,
        ),
        decoration: BoxDecoration(
          color: Color(0x1F999999),
          borderRadius: BorderRadius.all(Radius.circular(4))
        ),
      ),
      trailing: IconButton(
        icon: SpinItem(
          child: Icon(Icons.sync, color: Theme.of(context).primaryColor,),
          key: _spinKey,
        ),
        onPressed: (){
          if (_spinKey.currentState == null || _spinKey.currentState.isLoading) return;
          _spinKey.currentState?.startAnimation();
          GitAction action = repo.fetch();
          action.control();
          action.setOnComplete(() {
            action.release();
            if (action.hasError()) {
              Fluttertoast.showToast(msg: action.getError(), toastLength: Toast.LENGTH_LONG);
              _spinKey.currentState?.stopAnimation();
              return;
            }
            if (repo.localID() != repo.highID()) {
              GitAction action = repo.checkout().control();
              action.setOnComplete(() {
                action.release();
                if (action.hasError()) {
                  Fluttertoast.showToast(msg: action.getError(), toastLength: Toast.LENGTH_LONG);
                }
                _spinKey.currentState?.stopAnimation();
                setState(() { });
              });
            } else {
              _spinKey.currentState?.stopAnimation();
              setState(() { });
            }
          });
        },
      ),
      onTap: selectConfirm,
    );
  }

  @override
  Widget build(BuildContext context) {
    return (repo.isOpen() && project.isValidated) ? buildProject(context) : buildUnkown(context);
  }

}

class LibrariesPage extends HomeWidget {
  String _inputText;
  bool Function(String) onInsert;

  @override
  String get title => "manage_projects";

  LibrariesPage();

  @override
  State<StatefulWidget> createState() => _LibrariesPageState();

  void textInput(String text) {
    _inputText = text;
  }

  void addProject(BuildContext context, String url) {
    if (url.isEmpty) {
      return;
    }
    if (onInsert == null || !onInsert(url)) {
      Fluttertoast.showToast(
        msg: kt(context, "add_project_failed"),
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  buildActions(BuildContext context, reload) {
    return [
      IconButton(
          icon: Icon(Icons.add),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(kt(context, "new_project")),
                  content: TextField(
                    decoration: InputDecoration(
                      hintText: kt(context, "new_project_hint")
                    ),
                    onChanged: textInput,
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: (){
                        Navigator.of(context).pop();
                        addProject(context, _inputText);
                      },
                      child: Text(kt(context, "add"))
                    )
                  ],
                );
              },
            );
          }
      )
    ];
  }
}

String generateMd5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}

class _LibrariesPageState extends State<LibrariesPage> {
  Array data;
  LibraryContext ctx;
  BetterRefreshIndicatorController _controller;
  int pageIndex = 0;
  String _currentToken;
  bool hasMore = false;
  static DateTime lastUpdateTime;

  Future<bool> requestPage(int page) async {
    String url = LibURL.replaceAll("{0}", page.toString()).replaceAll("{1}", per_page.toString());
    http.Request request = http.Request("GET", Uri.parse(url));
    request.headers["Accept"] = "application/vnd.github.v3+json";
    http.StreamedResponse res = await request.send();
    String result = await res.stream.bytesToString();
    List<dynamic> json = jsonDecode(result);
    bool needLoad = false;

    for (int i = 0, t = json.length; i < t; ++i) {
      Map<String, dynamic> item = json[i];
      String body = item["body"];
      if (body != null) {
        if (ctx.parseLibrary(body)) {
          needLoad = true;
        }
      }
    }
    hasMore = json.length >= per_page;
    pageIndex = page;
    return needLoad;
  }

  void reload() async {
    int page = 0;
    _controller.startLoading();
    try {
      if (await requestPage(page)) {
        lastUpdateTime = DateTime.now();
        setState(() {});
      }
    } catch (e) {
    }
    _controller.stopLoading();
  }

  void loadMore() async {
    int page = pageIndex + 1;
    _controller.startLoading();
    try {
      if (await requestPage(page)) setState(() {});
    } catch (e) {
    }
    _controller.stopLoading();
  }

  bool onRefresh() {
    reload();
    return true;
  }

  bool insertLibrary(String url) {
    if (ctx.insertLibrary(url)) {
      setState(() { });
      return true;
    }
    return false;
  }

  bool onUpdateNotification(ScrollUpdateNotification notification) {
    if (hasMore &&
        notification.metrics.maxScrollExtent - notification.metrics.pixels < 20 &&
        !_controller.loading) {
        loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    var project = Project.getMainProject();
    bool hasProject = project != null;

    return BetterRefreshIndicator(
      child: NotificationListener<ScrollUpdateNotification>(
        child: ListView.separated(
          itemBuilder: (context, idx) {
            if (!hasProject) {
              if (idx == 0) {
                return Container(
                  color: Colors.lightGreenAccent,
                  padding: EdgeInsets.all(10),
                  child: Text(
                    kt("libraries_hit"),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyText1.copyWith(
                      color: Colors.indigo
                    ),
                  ),
                );
              } else {
                --idx;
              }
            }
            GitLibrary library = data[idx];
            String token = library.token;
            if (token.isEmpty) {
              String url = library.url;
              return Dismissible(
                key: GlobalObjectKey(url),
                background: Container(color: Colors.red,),
                child: LibraryCell(
                  data: data,
                  index: idx
                ),
                confirmDismiss: (_) async {
                  bool result = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(kt("remove_project")),
                        content: Text(kt("would_remove_project").replaceFirst("{0}", url)),
                        actions: [
                          TextButton(
                            onPressed: (){
                              Navigator.of(context).pop(false);
                            },
                            child: Text(kt("no"))
                          ),
                          TextButton(
                            onPressed: (){
                              Navigator.of(context).pop(true);
                            },
                            child: Text(kt("yes"))
                          ),
                        ],
                      );
                    }
                  );
                  return result == true;
                },
                onDismissed: (_) {
                  setState(() {
                    ctx.removeLibrary(url);
                  });
                },
              );
            } else {
              return LibraryCell(
                key: GlobalObjectKey(token),
                data: data,
                index: idx
              );
            }
          },
          separatorBuilder: (context, idx) {
            return Divider(height: 1,);
          },
          itemCount: hasProject ? data.length : data.length + 1
        ),
        onNotification: onUpdateNotification,
      ),
      controller: _controller,
    );
  }

  @override
  void didUpdateWidget(LibrariesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.onInsert = null;
    widget.onInsert = insertLibrary;
  }

  @override
  void initState() {
    super.initState();
    widget.onInsert = insertLibrary;
    _controller = BetterRefreshIndicatorController();
    _controller.onRefresh = onRefresh;
    ctx = LibraryContext.allocate();
    data = ctx.data.control();
    if (lastUpdateTime == null ||
        lastUpdateTime
            .add(Duration(minutes: 5))
            .isBefore(DateTime.now()))
      reload();
  }

  @override
  void dispose() {
    r(data);
    r(ctx);
    super.dispose();
    widget.onInsert = null;
    _controller.onRefresh = null;
  }
}