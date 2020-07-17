
import 'package:cache_image/cache_image.dart';
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
import 'package:kinoko/utils/progress_items.dart';
import 'package:kinoko/widgets/spin_itim.dart';
import 'dart:convert';
import 'dart:io';
import 'localizations/localizations.dart';
import 'widgets/home_widget.dart';

class LibraryCell extends StatefulWidget {

  GitLibrary library;

  LibraryCell(this.library);

  @override
  State<StatefulWidget> createState() {
    return _LibraryCellState(library);
  }
}

class _LibraryCellState extends State<LibraryCell> {

  GitLibrary library;
  GitRepository repo;
  Project project;
  String dirName;

  _LibraryCellState(this.library) {
    library.control();
    String name = Bit64.encodeString(library.url);
    project = Project.allocate(name);
    dirName = name;
    repo = GitRepository.allocate(name);
  }

  @override
  void dispose() {
    r(library);
    r(project);
    super.dispose();
  }

  ImageProvider getIcon() {
    if (project.isValidated) {
      String iconpath = project.fullpath + "/icon.png";
      File icon = new File(iconpath);
      if (icon.existsSync()) {
        return FileImage(icon);
      }
    }
    return CacheImage("http://tinygraphs.com/squares/${generateMd5(library.url)}?theme=bythepool&numcolors=3&size=180&fmt=jpg");
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
            FlatButton(
                onPressed: (){
                  Navigator.of(context).pop();
                },
                child: Text(kt("no"))
            ),
            FlatButton(
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
      });
    });
  }

  void selectMainProject() {
    project.setMainProject();
  }
  
  void selectConfirm() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(kt("confirm")),
          content: Text(kt("select_main_project")),
          actions: <Widget>[
            FlatButton(
                onPressed: (){
                  Navigator.of(context).pop();
                },
                child: Text(kt("no"))
            ),
            FlatButton(
                onPressed: (){
                  Navigator.of(context).pop();
                  selectMainProject();
                },
                child: Text(kt("yes"))
            )
          ],
        );
      }
    );
  }

  Widget buildUnkown(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.fromLTRB(16, 6, 10, 6),
      title: Text(library.url,),
      subtitle: Text(kt("not_installed")),
      leading: Image(
        image: getIcon()
      ),
      onTap: installConfirm,
    );
  }

  SpinItem spinItem;

  Widget buildProject(BuildContext context) {
    spinItem = SpinItem(
      child: Icon(Icons.sync, color: Theme.of(context).primaryColor,),
    );
    return ListTile(
      contentPadding: EdgeInsets.fromLTRB(16, 6, 10, 6),
      title: Text(project.name),
      subtitle: Text(project.subtitle),
      leading: Image(
        image: getIcon(),
      ),
      trailing: Column(
        children: <Widget>[
          IconButton(
            icon: spinItem,
            onPressed: (){
              spinItem.startAnimation();
              GitAction action = repo.fetch();
              action.control();
              action.setOnComplete(() {
                action.release();
                spinItem.stopAnimation();
              });
            },
          )
        ],
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
  _LibrariesPageState state;
  String _inputText;

  @override
  State<StatefulWidget> createState() {
    state = _LibrariesPageState();
    return state;
  }

  void textInput(String text) {
    _inputText = text;
  }

  void addProject(BuildContext context, String url) {
    if (GitLibrary.insertLibrary(url)) {
      state.updateList();
    } else {
      Fluttertoast.showToast(
        msg: kt(context, "add_project_failed"),
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  buildActions(BuildContext context) {
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
                    FlatButton(
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
  Array list;

  void updateList() {
    setState(() {
      r(list);
      list = GitLibrary.allLibraries().control();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (list == null) {
      list = GitLibrary.allLibraries().control();
    }

    return ListView.separated(
        itemBuilder: (context, idx) {
          return LibraryCell(list[idx]);
        },
        separatorBuilder: (context, idx) {
          return Divider();
        },
        itemCount: list.length
    );
  }

  @override
  void dispose() {
    r(list);
    super.dispose();
  }
}