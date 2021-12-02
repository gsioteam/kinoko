
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/main/models.dart';
import 'package:kinoko/utils/image_providers.dart';
import 'package:kinoko/utils/plugin/plugin.dart';
import 'package:kinoko/utils/plugins_manager.dart';
import 'package:kinoko/widgets/no_data.dart';
import 'package:kinoko/widgets/progress_dialog.dart';
import 'package:kinoko/widgets/spin_itim.dart';
import 'dart:convert';
import '../localizations/localizations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dapp/src/widgets/drefresh.dart';
import 'package:flutter_git/flutter_git.dart';

const LibURL = "https://api.github.com/repos/gsioteam/env/issues/3/comments?per_page={1}&page={0}";
const int _pageLimit = 40;

class GitItem extends ProgressItem {
  GitController controller;
  GitItem(this.controller) : super(ProgressValue(label: "...")) {
    onCancel = _onCancel;
    controller.addListener(_update);
    _wait();
  }

  void _onCancel() {
    controller.cancel();
  }

  void _wait() async {
    try {
      await controller.completer.future;
      value = value.copyWith(
        status: ProgressStatus.Success,
      );
    } catch (e) {
      value = value.copyWith(
        status: ProgressStatus.Failed,
      );
    } finally {
      controller.dispose();
    }
  }

  void _update() {
    value = ProgressValue(
      label: "${controller.value.event} (${controller.value.content})",
    );
  }
}

class LibraryCell extends StatefulWidget {

  final PluginInfo item;
  final VoidCallback? onSelect;

  LibraryCell({
    Key? key,
    required this.item,
    this.onSelect,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LibraryCellState();
  }
}

class _LibraryCellState extends State<LibraryCell> {
  Plugin? plugin;
  late GitRepository repo;

  _LibraryCellState();

  @override
  void initState() {
    super.initState();

    String id = PluginsManager.instance.calculatePluginID(widget.item.src);
    plugin = PluginsManager.instance.findPlugin(id);

    repo = GitRepository("${PluginsManager.instance.root.path}/$id");
    repo.open();
  }

  @override
  void dispose() {
    super.dispose();
    repo.dispose();
  }

  Future<void> clone() async {
     Directory dir = Directory(repo.path);
     if (await dir.exists()) {
       await dir.delete(recursive: true);
     }
     await dir.create(recursive: true);

     await showDialog(
       context: context,
       builder: (context) {
         return ProgressDialog(
           title: kt("clone_project"),
           run: () {
             GitController controller = GitController(repo);
             repo.clone(controller,
               url: widget.item.src,
               branch: widget.item.branch??"master",
             );

             return GitItem(controller);
           },
         );
       }
     );
     setState(() {
       this.plugin = PluginsManager.instance.findPlugin(PluginsManager.instance.calculatePluginID(widget.item.src));
     });
  }

  Widget _buildCloned(BuildContext context, Plugin plugin) {
    PluginInformation pluginInformation = plugin.information!;
    List<InlineSpan> icons = [
      TextSpan(text: pluginInformation.name),
    ];
    bool isMain = plugin == PluginsManager.instance.current;
    if (isMain) {
      icons.insert(0, WidgetSpan(child: Icon(Icons.arrow_right, color: Colors.blueAccent,)));
    }
    String branch = widget.item.branch ?? "master";
    bool hasNew = repo.getSHA1("refs/heads/$branch") != repo.getSHA1("refs/remotes/origin/$branch");

    return Material(
      color: Theme.of(context).canvasColor,
      child: ListTile(
        title: Text.rich(TextSpan(
            children: icons
        )),
        subtitle: Text("Ver. ${repo.getSHA1("refs/heads/${widget.item.branch??"master"}").substring(0, 7)}"),
        leading: Container(
          child: pluginImage(
            plugin,
            width: 56,
            height: 56,
            errorBuilder: (context, e, stack) {
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Color(0x1F999999),
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white,
                ),
              );
            },
          ),
          decoration: BoxDecoration(
              color: Color(0x1F999999),
              borderRadius: BorderRadius.all(Radius.circular(4))
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasNew) Icon(
              Icons.upgrade,
              color: Colors.red,
              size: 18,
            ),
            IconButton(
              icon: SpinItem(
                child: Icon(Icons.sync, color: Theme.of(context).primaryColor,),
              ),
              onPressed: () async {

                try {
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return ProgressDialog(
                        title: kt("fetch"),
                        run: () {
                          GitController controller = GitController(repo);
                          repo.fetch(controller,);

                          return GitItem(controller);
                        },
                      );
                    },
                  );
                  String branch = widget.item.branch??"master";
                  if (repo.getSHA1("refs/heads/$branch") != repo.getSHA1("refs/remotes/origin/$branch")) {
                    await showDialog(
                        context: context,
                        builder: (context) {
                          return ProgressDialog(
                            title: kt("checkout"),
                            run: () {
                              GitController controller = GitController(repo);
                              repo.checkout(controller, branch: branch);

                              return GitItem(controller);
                            },
                          );
                        }
                    );
                    setState(() {
                      this.plugin = PluginsManager.instance.findPlugin(
                          PluginsManager.instance.calculatePluginID(widget.item.src),
                          true
                      );
                      if (isMain)
                        PluginsManager.instance.current = this.plugin;
                    });
                  }
                } catch (e) {
                  Fluttertoast.showToast(msg: e.toString(), toastLength: Toast.LENGTH_LONG);
                } finally {
                }
              },
            )
          ],
        ),
        onTap: PluginsManager.instance.current == plugin ? null : () async {
          bool? ret = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(kt("confirm")),
                content: Text(kt("select_main_project")),
                actions: [
                  TextButton(
                    child: Text(kt("no")),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  TextButton(
                    child: Text(kt("yes")),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              );
            }
          );

          if (ret == true) {
            PluginsManager.instance.current = plugin;
          }
        },
      ),
    );
  }

  Widget _buildPlugin(BuildContext context) {
    return Material(
      color: Theme.of(context).canvasColor,
      child: ListTile(
        title: Text(widget.item.title),
        subtitle: Text(kt("not_installed")),
        leading: widget.item.icon == null ? buildIdenticon(
          widget.item.src,
          width: 56,
          height: 56,
        ) : Image(
          image: networkImageProvider(widget.item.icon!),
          width: 56,
          height: 56,
        ),
        onTap: () async {
          var ret = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(kt("confirm")),
                content: Text(kt("install_confirm").replaceFirst("{url}", widget.item.src)),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: Text(kt("no")),
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: Text(kt("yes"))
                  ),
                ],
              );
            }
          );
          if (ret == true) {
            await clone();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (plugin?.isValidate == true && repo.isVisible) {
      return _buildCloned(context, plugin!);
    } else {
      return _buildPlugin(context);
    }
  }

}

class LibrariesPage extends StatefulWidget {

  LibrariesPage({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LibrariesPageState();


}

class _LibrariesPageState extends State<LibrariesPage> {
  int pageIndex = 0;
  bool loading = false;
  bool _disposed = false;
  late TokenContainer container;

  Future<bool> requestPage(int page) async {
    String url = LibURL.replaceAll("{0}", page.toString()).replaceAll("{1}", _pageLimit.toString());
    http.Request request = http.Request("GET", Uri.parse(url));
    request.headers["Accept"] = "application/vnd.github.v3+json";
    http.StreamedResponse res = await request.send();
    String result = await res.stream.bytesToString();
    List json = jsonDecode(result);

    PluginsManager.instance.update(
      json,
      container,
      page == 0,
    );
    bool hasMore = json.length >= _pageLimit;
    pageIndex = page;
    return hasMore;
  }

  void reload() async {
    setState(() {
      loading = true;
    });
    int page = 0;

    container = TokenContainer();
    while (await requestPage(page)) {
      page++;
    }
    PluginsManager.instance.lastUpdate = DateTime.now();
    if (_disposed) return;
    setState(() {
      loading = false;
    });
  }

  void onRefresh() {
    reload();
  }

  bool insertLibrary(String url, String branch) {
    if (PluginsManager.instance.add(PluginInfo(
        title: url,
        src: url,
        branch: branch
    ))) {
      setState(() { });
      return true;
    }
    return false;
  }

  void addProject(BuildContext context, String url, String branch) {
    if (url.isEmpty) {
      return;
    }
    if (branch.isEmpty) {
      branch = 'master';
    }

    if (insertLibrary(url, branch) == false) {
      Fluttertoast.showToast(
        msg: kt("add_project_failed"),
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kt("manage_projects")),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              TextEditingController urlController = TextEditingController();
              TextEditingController branchController = TextEditingController();
              var ret = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(kt("new_project")),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            labelText: kt("new_project_hint"),
                          ),
                          controller: urlController,
                        ),
                        TextField(
                          decoration: InputDecoration(
                              labelText: kt("new_project_branch")
                          ),
                          controller: branchController,
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: (){
                          Navigator.of(context).pop(true);
                        },
                        child: Text(kt("add")),
                      ),
                    ],
                  );
                },
              );

              if (ret == true) {
                addProject(context, urlController.text, branchController.text);
              }
              await Future.delayed(Duration(seconds: 1));
              urlController.dispose();
              branchController.dispose();
            }
          )
        ],
      ),
      body: DRefresh(
        loading: loading,
        child: _buildBody(),
        onRefresh: onRefresh,
      ),
    );
  }

  Widget _buildBody() {
    var data = PluginsManager.instance.plugins.data;
    if (data.length > 0) {
      return ListView.separated(
          itemBuilder: (context, idx) {
            var item = data[idx];
            return Dismissible(
              key: ValueKey(item.src),
              background: Container(color: Theme.of(context).errorColor,),
              child: LibraryCell(
                item: item,
                onSelect: () {
                  setState(() { });
                },
              ),
              confirmDismiss: (_) async {
                bool? result = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(kt("remove_project")),
                        content: Text(kt("would_remove_project").replaceFirst("{0}", item.src)),
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
                  PluginsManager.instance.remove(item);
                  // AppStatusNotification().dispatch(context);
                });
              },
            );
          },
          separatorBuilder: (context, idx) => Divider(height: 1,),
          itemCount: data.length
      );
    } else {
      return NoData();
    }

  }

  @override
  void didUpdateWidget(LibrariesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();

    PluginsManager.instance.plugins.addListener(_update);
    PluginsManager.instance.addListener(_update);
    if (DateTime.now().difference(PluginsManager.instance.lastUpdate).inSeconds > 3600) {
      Future.delayed(Duration.zero).then((value) => reload());
    }
  }

  @override
  void dispose() {
    super.dispose();

    PluginsManager.instance.plugins.removeListener(_update);
    PluginsManager.instance.removeListener(_update);
    _disposed = true;
  }

  void _update() {
    setState(() { });
  }
}