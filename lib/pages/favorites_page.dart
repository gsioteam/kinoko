

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:decorated_icon/decorated_icon.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:glib/main/models.dart';
import 'package:kinoko/utils/file_utils.dart';
import 'package:kinoko/utils/js_extensions.dart';
import 'package:kinoko/utils/plugin/plugin.dart';
import 'package:kinoko/utils/plugins_manager.dart';
import 'package:path/path.dart' as path;
import '../configs.dart';
import '../utils/neo_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../localizations/localizations.dart';
import '../utils/favorites_manager.dart';
import '../widgets/instructions_dialog.dart';
import '../widgets/favorite_item.dart';

import '../widgets/no_data.dart';

class _FavData extends FavoriteItemData {

  FavCheckItem item;

  _FavData(this.item);

  @override
  bool get hasNew => item.value;

  @override
  ImageProvider<Object> get imageProvider => NeoImageProvider(
      uri: Uri.parse(item.info.picture ?? "")
  );

  @override
  String get subtitle => "[${item.last.name.isNotEmpty ? item.last.name : item.info.subtitle}]";

  @override
  String get title => item.info.title;

  @override
  bool get hasData => item.info.picture != null;

  @override
  void addListener(VoidCallback listener) {
    item.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    item.removeListener(listener);
  }
}

class _FavKey extends GlobalObjectKey {
  _FavKey(value) : super(value);
}

class FavoritesPage extends StatefulWidget {

  FavoritesPage({Key? key}) : super(key: key,);

  @override
  State<StatefulWidget> createState() {
    return _FavoritesPageState();
  }

}

class _FavoritesPageState extends State<FavoritesPage> {
  GlobalKey<AnimatedListState> _listKey = GlobalKey();

  itemClicked(int idx) async {
    var items = FavoritesManager().items.data;
    FavCheckItem checkItem = items[idx];
    Plugin? plugin = PluginsManager.instance.findPlugin(checkItem.pluginID);
    if (plugin?.isValidate == true) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        var theme = Theme.of(context).appBarTheme.systemOverlayStyle;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          child: DApp(
            entry: checkItem.bookPage,
            fileSystems: [plugin!.fileSystem],
            classInfo: kiControllerInfo,
            controllerBuilder: (script, state) => KiController(script, plugin)..state = state,
            initializeData: checkItem.info.data,
            onInitialize: (script) {
              script.addClass(downloadManager);
              Configs.instance.setupJS(script, plugin);
            },
          ),
          value: theme!,
        );
      }));
    } else {
      Fluttertoast.showToast(msg: kt("no_project_found"));
    }
  }

  void onRemoveItem(FavCheckItem item) async {
    var items = FavoritesManager().items.data;
    int index = items.indexOf(item);
    if (index >= 0) {

      var result = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(kt("confirm")),
            content: Text(kt("delete_item_2").replaceAll("{0}", item.info.title)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text(kt('no')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text(kt('yes')),
              ),
            ],
          );
        }
      );

      if (result == true) {
        removeItem(item);
      }
    }
  }

  void reverseItem(FavCheckItem item, int index) {
    var items = FavoritesManager().items.data;
    setState(() {
      if (index < items.length) {
        items.insert(index, item);
      } else {
        index = items.length;
        items.add(item);
      }
    });
    _listKey.currentState?.insertItem(index, duration: Duration(milliseconds: 300));
  }

  void removeItem(FavCheckItem item) {
    setState(() {
      FavoritesManager().remove(item.info.key);
    });
  }

  Widget buildGridView(BuildContext context, List<FavCheckItem> items) {
    return AnimationLimiter(
      child: GridView.builder(
        key: _listKey,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          childAspectRatio: 0.66
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          FavCheckItem item = items[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: FavoriteItem(
                  key: _FavKey(item),
                  item: _FavData(item),
                  onTap: () {
                    itemClicked(index);
                  },
                  onDismiss: () {
                    onRemoveItem(item);
                  },
                  onMoveToFirst: () {
                    setState(() {
                      items.remove(item);
                      items.insert(0, item);
                      FavoritesManager().reorder();
                    });
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  final GlobalKey _actionKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    var items = FavoritesManager().items.data;
    return Scaffold(
      body: items.length > 0 ? buildGridView(context, items) : NoData(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.menu),
        key: _actionKey,
        onPressed: () {
          var renderObject = _actionKey.currentContext?.findRenderObject();
          var translation = renderObject!.getTransformTo(null).getTranslation();
          var rect = renderObject.semanticBounds;
          showMenu(
              context: context,
              position: RelativeRect.fromLTRB(
                  translation.x, translation.y,
                  translation.x + rect.width,
                  translation.y + rect.height,
              ),
              items: [
                PopupMenuItem(
                  child: Text(kt("export_list")),
                  onTap: export,
                ),
                PopupMenuItem(
                  child: Text(kt("import_list")),
                  onTap: import,
                ),
                PopupMenuItem(
                  child: Text(kt("clear_list")),
                  onTap: clear,
                ),
              ]
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  final GlobalKey iconKey = GlobalKey();

  List<Widget> buildActions(BuildContext context,) {
    bool has = KeyValue.get("$viewed_key:fav") == "true";
    return [
      IconButton(
        key: iconKey,
        onPressed: () {
          showInstructionsDialog(context, 'assets/fav',
            entry: kt('lang'),
          );
        },
        icon: Icon(Icons.help_outline),
        color: has ? AppBarTheme.of(context).iconTheme?.color ?? IconTheme.of(context).color : Colors.transparent,
      ),
    ];
  }

  void export() async {
    await Future.delayed(Duration.zero);
    if (FavoritesManager().items.data.length == 0) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(kt('export_failed')),
            content: Text(kt('empty_list')),
            actions: [
              TextButton(
                child: Text(kt('ok')),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        }
      );
      return;
    }
    List<Map> items = [];
    for (var item in FavoritesManager().items.data) {
      items.add(item.toData());
    }
    var json = jsonEncode(items);
    var res = await FileUtils.openDir(context);
    if (res != null) {
      TextEditingController textEditingController = TextEditingController(
        text: 'kinoko_book_list.json'
      );
      var check = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(kt('file_name')),
              content: TextField(
                controller: textEditingController,
              ),
              actions: [
                TextButton(
                  child: Text(kt('cancel')),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text(kt('yes')),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          }
      );
      if (check == true && textEditingController.text.trim().isNotEmpty) {
        File file = File(path.join(res, textEditingController.text.trim()));
        if (await file.exists()) {
          check = await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(kt('confirm')),
                  content: Text(kt('file_exist')),
                  actions: [
                    TextButton(
                      child: Text(kt('cancel')),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                    ),
                    TextButton(
                      child: Text(kt('yes')),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                    ),
                  ],
                );
              }
          );
          if (check == true) {
            await file.delete(recursive: true);
          }
        }

        if (check == true) {
          await file.writeAsString(json);
        }
      }
    }
  }

  void import() async {
    var res = await FileUtils.openFile(context);

    if (res != null) {
      File file = File(res);
      var data = await jsonDecode(await file.readAsString());
      try {
        var manager = FavoritesManager();
        List<FavCheckItem> exists = [];
        List<FavCheckItem> items = [];
        for (var itemData in data) {
          var item = FavCheckItem.fromData(manager, itemData);
          if (manager.isFavorite(item.info.key)) {
            exists.add(item);
          } else {
            items.add(item);
          }
        }
        var check = await showDialog<bool>(
            context: context,
            builder: (context) {
              var size = MediaQuery.of(context).size;
              return AlertDialog(
                title: Text(kt('import_list')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kt('import_des')
                        .replaceFirst('{0}', items.length.toString())
                        .replaceFirst('{1}', exists.length.toString())
                    ),
                    Container(
                      padding: EdgeInsets.only(
                        top: 6
                      ),
                      height: 180,
                      width: size.width * 0.68,
                      child: ListView.builder(
                        itemBuilder: (context, index) {
                          FavCheckItem item;
                          if (index < items.length) {
                            item = items[index];
                          } else {
                            item = exists[index - items.length];
                          }
                          var exist = index < items.length;
                          
                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.info.title,
                                  softWrap: true,
                                  maxLines: 1,
                                ),
                              ),
                              Text(exist ? kt('add') : kt('exist'))
                            ],
                          );
                        },
                        itemCount: items.length + exists.length,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: Text(kt('no')),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  TextButton(
                    child: Text(kt('yes')),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              );
            }
        );
        if (check == true) {
          setState(() {
            manager.items.data.addAll(items);
            manager.items.update();
          });
        }
      } catch (e) {
        Fluttertoast.showToast(
            msg: "${kt('import_failed')}\n${e.toString()}"
        );
      }
    }
  }

  void clear() {
    setState(() {
      FavoritesManager().clear();
    });
  }
}