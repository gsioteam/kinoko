
import 'dart:io';

import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kinoko/localizations/localizations.dart';
import 'package:kinoko/utils/import_manager.dart';
import 'package:kinoko/widgets/no_data.dart';
import 'package:path_provider_ex/path_provider_ex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

import '../utils/file_loader.dart';
import '../utils/fullscreen.dart';
import '../utils/picture_data.dart';
import '../widgets/favorite_item.dart';
import '../widgets/pager/pager.dart';
import 'picture_viewer.dart';

class ImportedPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ImportedPageState();
}

class _FavKey extends GlobalObjectKey {
  _FavKey(value) : super(value);
}

class ImportedData extends FavoriteItemData {
  ImportedItem item;
  FileLoader? _loader;
  String? _cover;
  List<VoidCallback> _callbacks = [];

  ImportedData(this.item) {
    fetch();
  }

  void fetch() async {
    _loader = await FileLoader.create(item.path);
    _cover = await _loader?.getPictures().first;
    for (var fn in _callbacks) {
      fn();
    }
  }

  @override
  void addListener(VoidCallback listener) {
    _callbacks.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _callbacks.remove(listener);
  }

  @override
  bool get hasData => _cover != null;

  @override
  bool get hasNew => false;

  @override
  ImageProvider<Object> get imageProvider {
    return FileImage(File("${_loader!.path}$_cover"));
  }

  @override
  String get subtitle => "";

  @override
  String get title => item.title;

}

class _ImportedPageState extends State<ImportedPage> {
  GlobalKey<AnimatedListState> _listKey = GlobalKey();

  List<ImportedData> _items = [];

  List<ImportedData> getItems() {
    var items = ImportManager.instance.items.data;
    Map<ImportedItem, ImportedData> cached = {};
    ImportedData createOrGet(ImportedItem item, int off) {
      if (cached.containsKey(item)) {
        return cached.remove(item)!;
      } else {
        for (int i = 0, t = _items.length; i < t; ++i) {
          var oi = _items[i];
          if (oi.item == item) {
            return _items.removeAt(i);
          }
        }
        return ImportedData(item);
      }
    }

    for (int i = 0, t = items.length; i < t; ++i) {
      var ni = items[i];
      if (_items.length <= i) {
        _items.add(createOrGet(ni, i));
      } else {
        var oi = _items[i];
        if (oi.item != ni) {
          var replace = _items[i];
          cached[replace.item] = replace;
          _items[i] = createOrGet(ni, i + 1);
        }
      }
    }
    _items.length = items.length;
    return _items;
  }

  @override
  Widget build(BuildContext context) {
    var items = getItems();
    return Scaffold(
      body: items.length > 0 ? buildGridView(context, items) : NoData(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        // PopupMenuButton(
        //   icon: Icon(Icons.more_vert),
        //   itemBuilder: (context) {
        //     return [
        //       PopupMenuItem(
        //         child: Text(kt("add")),
        //         onTap: importBook,
        //       ),
        //     ];
        //   }
        // ),
        onPressed: importBook,
      ),
    );
  }

  Widget buildGridView(BuildContext context, List<ImportedData> items) {
    return AnimationLimiter(
      child: GridView.builder(
        key: _listKey,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.66
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          ImportedData item = items[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: FavoriteItem(
                  key: _FavKey(item),
                  item: item,
                  onTap: () {
                    itemClicked(item);
                  },
                  onDismiss: () {
                    onRemoveItem(item);
                  },
                  onMoveToFirst: () {
                    setState(() {
                      var items = ImportManager.instance.items;
                      items.data.remove(item.item);
                      items.data.insert(0, item.item);
                      items.update();
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

  void importBook() async {
    var status = await Permission.storage.status;
    switch (status) {
      case PermissionStatus.granted:
        break;
      default: {
        var status = await Permission.storage.request();
        if (status != PermissionStatus.granted) {
          Fluttertoast.showToast(
              msg: kt("no_permission")
          );
          return;
        }
      }
    }
    var lists = await PathProviderEx.getStorageInfo();
    if (lists.length > 0) {
      var info = lists.last;
      var res = await Navigator.of(context).push<String>(MaterialPageRoute(
          builder: (context) {
            return FilesystemPicker(
              rootDirectory: Directory(info.rootDir),
              fileTileSelectMode: FileTileSelectMode.checkButton,
              onSelect: (path) {
                Navigator.of(context).pop(path);
              },
            );
          }
      ));
      if (res != null) {
        FileLoader? loader = await FileLoader.create(res);
        if (loader != null) {
          var pictures = loader.getPictures();
          var list = await pictures.toList();
          if (list.isEmpty) {
            Fluttertoast.showToast(msg: kt('no_picture_found'));
          } else {
            TextEditingController textController = TextEditingController(
                text: path.basenameWithoutExtension(res)
            );
            var name = await showDialog<String>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(kt('import_title')),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(kt('import_details').replaceFirst('{0}', list.length.toString())),
                        TextField(
                          controller: textController,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(kt('cancel'))
                      ),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(textController.text);
                          },
                          child: Text(kt('confirm'))
                      ),
                    ],
                  );
                }
            );
            Future.delayed(Duration(seconds: 1)).then((value) => textController.dispose());
            if (name != null) {
              var item = ImportedItem(
                  title: name,
                  path: res);
              var index = ImportManager.instance.items.data.length;
              ImportManager.instance.add(item);

              if (_listKey.currentState == null) {
                setState(() {
                });
              } else {
                _listKey.currentState?.insertItem(index);
              }
            }
          }
        } else {
          Fluttertoast.showToast(msg: kt('unsupport_file'));
        }
      }
    }
  }

  void onRemoveItem(ImportedData item) async {
    var index = _items.indexOf(item);
    if (index >= 0) {
      var result = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(kt("confirm")),
              content: Text(kt("delete_item_2").replaceAll("{0}", item.title)),
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

  void removeItem(ImportedData item) {
    setState(() {
      ImportManager.instance.remove(item.item);
    });
  }

  itemClicked(ImportedData data) async {
    ImportedItem item = data.item;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) {
          return PictureViewer(
            data: LocalPictureData(
              path: item.path,
              title: item.title,
            ),
          );
        }
    ));
    exitFullscreenMode(context);
  }
}