

import 'package:cache_image/cache_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/project.dart';
import 'configs.dart';
import 'widgets/home_widget.dart';
import 'widgets/book_item.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'localizations/localizations.dart';
import 'book_page.dart';
import 'picture_viewer.dart';
import 'utils/favorites_manager.dart';
import 'widgets/better_snack_bar.dart';

class FavoriteItem extends StatefulWidget {
  void Function() onTap;
  FavCheckItem item;

  FavoriteItem({
    Key key,
    this.onTap,
    this.item
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FavoriteItemState();
}

class _FavoriteItemState extends State<FavoriteItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.item.item.title),
      subtitle: Text(widget.item.item.subtitle),
      leading: Image(
        image: CacheImage(widget.item.item.picture),
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
    );
  }

  onStateChanged() {
    setState(() { });
  }

  @override
  void initState() {
    super.initState();
    widget.item.onStateChanged = onStateChanged;
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

class FavoritesPage extends HomeWidget {
  @override
  String get title => "favorites";

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
    if (type == DataItemType.Book) {
      ctx = project.createBookContext(item).control();
    } else if (type == DataItemType.Chapter) {
      ctx = project.createChapterContext(item).control();
    } else {
      Fluttertoast.showToast(msg: kt("can_not_determine_the_context_type"));
      project.release();
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      if (type == DataItemType.Book) {
        return BookPage(ctx, project);
      } else {
        return PictureViewer(ctx);
      }
    }));
    setState(() {});
    ctx.release();
    project.release();
  }

  void onRemoveItem(FavCheckItem item) async {
    print("Remove!");
    int index = items.indexOf(item);
    if (index >= 0) {
      items.removeAt(index);
      _listKey.currentState.removeItem(index, (context, animation) {
        return Container();
      }, duration: Duration(milliseconds: 0));

      BetterSnackBar<bool> snackBar;
      snackBar = BetterSnackBar<bool>(
        title: kt("confirm"),
        subtitle: kt("delete_item_2").replaceAll("{0}", item.item.title),
        trailing: FlatButton(
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
    if (index < items.length) {
      items.insert(index, item);
    } else {
      index = items.length;
      items.add(item);
    }
    print("reverse ${item.item.title}");
    _listKey.currentState.insertItem(index, duration: Duration(milliseconds: 300));
  }

  void removeItem(FavCheckItem item) {
    print("remove ${item.item.title}");
    FavoritesManager().remove(item);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      initialItemCount: items.length,
      itemBuilder: (context, index, animation) {
        FavCheckItem item = items[index];
        return SizeTransition(
          sizeFactor: animation,
          child: Dismissible(
            key: ObjectKey(item),
            child: FavoriteItem(
              item: item,
              onTap: () {
                itemClicked(index);
              },
            ),
            onDismissed: (direction) {
              onRemoveItem(item);
            },
          ),
        );
      },
    );
  }

  @override
  void initState() {
    items = List<FavCheckItem>.from(FavoritesManager().items);
    super.initState();
  }

  @override
  void dispose() {
    print(snackBars.length);
    snackBars.forEach((element) {
      element.dismiss(false);
    });
    snackBars.clear();
    super.dispose();
  }
}