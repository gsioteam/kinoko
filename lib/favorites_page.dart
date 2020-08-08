

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
      onTap: widget.onTap,
    );
  }

  onStateChanged() {
    setState(() {
    });
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
    ctx.release();
    project.release();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return FavoriteItem(
          item: items[index],
          onTap: () {
            itemClicked(index);
          },
        );
      },
      separatorBuilder: (context, idx)=>Divider(),
    );
  }

  @override
  void initState() {
    items = List<FavCheckItem>.from(FavoritesManager().items);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }
}