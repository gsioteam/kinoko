

import 'package:decorated_icon/decorated_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:glib/main/models.dart';
import 'package:kinoko/utils/js_extensions.dart';
import 'package:kinoko/utils/plugin/plugin.dart';
import 'package:kinoko/utils/plugins_manager.dart';
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
        return DApp(
          entry: checkItem.bookPage,
          fileSystems: [plugin!.fileSystem],
          classInfo: kiControllerInfo,
          controllerBuilder: (script, state) => KiController(script, plugin)..state = state,
          initializeData: checkItem.info.data,
          onInitialize: (script) {
            script.addClass(downloadManager);
            Configs.instance.setupJS(script, plugin);
          },
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

  @override
  Widget build(BuildContext context) {
    var items = FavoritesManager().items.data;
    return items.length > 0 ? buildGridView(context, items) : NoData();
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
}