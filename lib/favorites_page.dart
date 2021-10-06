

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/models.dart';
import 'package:glib/main/project.dart';
import 'configs.dart';
import 'main.dart';
import 'utils/neo_cache_manager.dart';
import 'widgets/book_item.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'localizations/localizations.dart';
import 'book_page.dart';
import 'picture_viewer.dart';
import 'utils/favorites_manager.dart';
import 'widgets/better_snack_bar.dart';
import 'widgets/instructions_dialog.dart';

class _FavKey extends GlobalObjectKey {
  _FavKey(value) : super(value);
}

class FavoriteItem extends StatefulWidget {
  final VoidCallback onTap;
  final FavCheckItem item;
  final Animation<double> animation;
  final VoidCallback onDismiss;

  FavoriteItem({
    Key key,
    this.onTap,
    this.item,
    this.animation,
    this.onDismiss
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FavoriteItemState();
}

class _FavoriteItemState extends State<FavoriteItem> {
  String title;
  String subtitle;
  String picture;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: widget.animation,
      child: Dismissible(
        key: ObjectKey(widget.item),
        background: Container(color: Colors.red,),
        child: Column(
          children: [
            ListTile(
              title: Text(title),
              subtitle: Text(subtitle),
              leading: Image(
                image: NeoImageProvider(
                  uri: Uri.parse(picture),
                  cacheManager: NeoCacheManager.defaultManager,
                ),
                fit: BoxFit.cover,
                width: 56,
                height: 56,
                gaplessPlayback: true,
              ),
              onTap: () {
                setState(() {
                  widget.onTap();
                });
              },
              trailing: widget.item.hasNew ? Icon(Icons.fiber_new, color: Colors.red,) : null,
            ),
            Divider(height: 1,)
          ],
        ),
        onDismissed: (direction) {
          widget.onDismiss?.call();
        },
      ),
    );
  }

  onStateChanged() {
    setState(() { });
  }

  @override
  void initState() {
    super.initState();
    widget.item.onStateChanged = onStateChanged;
    title = widget.item.item.title;
    subtitle = widget.item.item.subtitle;
    picture = widget.item.item.picture;
  }

  @override
  void dispose() {
    super.dispose();
    widget.item.onStateChanged = null;
  }

  @override
  void didUpdateWidget(FavoriteItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.item.onStateChanged = onStateChanged;
  }
}

class FavoritesPage extends StatefulWidget {

  FavoritesPage({Key key}) : super(key: key,);

  @override
  State<StatefulWidget> createState() {
    return _FavoritesPageState();
  }

}

class _FavoritesPageState extends State<FavoritesPage> {
  List<FavCheckItem> items;
  List<BetterSnackBar<bool>> snackBars = List();
  GlobalKey<AnimatedListState> _listKey = GlobalKey();

  itemClicked(int idx) async {
    FavCheckItem checkItem = items[idx];
    DataItem item = checkItem.item;
    Project project = Project.allocate(item.projectKey);
    if (!project.isValidated) {
      Fluttertoast.showToast(msg: kt("no_project_found"));
      project.release();
      return;
    }
    DataItemType type = item.type;
    Context ctx;
    if (type == DataItemType.Data) {
      ctx = project.createCollectionContext(BOOK_INDEX, item).control();
      ctx.autoReload = true;
    } else {
      Fluttertoast.showToast(msg: kt("can_not_determine_the_context_type"));
      project.release();
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return BookPage(ctx, project);
    }));
    setState(() {});
    ctx.release();
    project.release();
  }

  void onRemoveItem(FavCheckItem item) async {
    int index = items.indexOf(item);
    if (index >= 0) {
      setState(() {
        items.removeAt(index);
      });
      _listKey.currentState.removeItem(index, (context, animation) {
        return Container();
      }, duration: Duration(milliseconds: 0));

      BetterSnackBar<bool> snackBar;
      snackBar = BetterSnackBar<bool>(
        title: kt("confirm"),
        subtitle: kt("delete_item_2").replaceAll("{0}", item.item.title),
        trailing: TextButton(
          child: Text(kt("undo"), style: Theme.of(context).textTheme.bodyText2.copyWith(color: Colors.white, fontWeight: FontWeight.bold),),
          onPressed: () {
            snackBar.dismiss(true);
          },
        ),
        duration: Duration(seconds: 5)
      );


      snackBars.add(snackBar);

      bool result = await snackBar.show(context);
      print("dismiss ${item.item.title}");
      if (result == true) {
        reverseItem(item, index);
      } else {
        removeItem(item);
      }

      snackBars.remove(snackBar);
    }
  }

  void reverseItem(FavCheckItem item, int index) {
    setState(() {
      if (index < items.length) {
        items.insert(index, item);
      } else {
        index = items.length;
        items.add(item);
      }
    });
    _listKey.currentState.insertItem(index, duration: Duration(milliseconds: 300));
  }

  void removeItem(FavCheckItem item) {
    FavoritesManager().remove(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kt("favorites")),
        actions: buildActions(context),
      ),
      body: items.length > 0 ? AnimatedList(
        key: _listKey,
        initialItemCount: items.length,
        itemBuilder: (context, index, animation) {
          FavCheckItem item = items[index];
          return FavoriteItem(
            key: _FavKey(item),
            animation: animation,
            item: item,
            onTap: () {
              itemClicked(index);
            },
            onDismiss: () {
              onRemoveItem(item);
            },
          );
        },
      ) : Container(
        child: Center(
          child: Text(
            kt('no_data'),
            style: TextStyle(
              fontFamily: 'DancingScript',
              fontSize: 24,
              color: Theme.of(context).disabledColor,
              shadows: [
                Shadow(
                  color: Theme.of(context).colorScheme.surface,
                  offset: Offset(1, 1)
                ),
              ]
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    items = List<FavCheckItem>.from(FavoritesManager().items);
    super.initState();

    if (KeyValue.get("$viewed_key:fav") != "true") {
      Future.delayed(Duration(milliseconds: 300)).then((value) async {
         await showInstructionsDialog(context, 'assets/fav',
            entry: kt('lang'),
            onPop: () async {
              final renderObject = iconKey.currentContext.findRenderObject();
              Rect rect = renderObject?.paintBounds;
              var translation = renderObject?.getTransformTo(null)?.getTranslation();
              if (rect != null && translation != null) {
                return rect.shift(Offset(translation.x, translation.y));
              }
              return null;
            }
        );
         KeyValue.set("$viewed_key:fav", "true");
         AppStatusNotification().dispatch(context);
      });
    }

  }

  @override
  void dispose() {
    snackBars.forEach((element) {
      element.dismiss(false);
    });
    snackBars.clear();
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
        color: has ? Colors.white : Colors.transparent,
      ),
    ];
  }
}