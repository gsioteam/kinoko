

import 'package:cached_network_image/cached_network_image.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
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
import 'widgets/instructions_dialog.dart';
import 'dart:ui' as ui;

import 'widgets/no_data.dart';

const Size _containerSize = Size(120, 180);
const double _frameOffset = 5;

class BookFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(_frameOffset, -_frameOffset);
    path.lineTo(_frameOffset + size.width, -_frameOffset);
    path.lineTo(_frameOffset + size.width, -_frameOffset + size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    Paint paint = Paint();
    paint.style = PaintingStyle.fill;
    paint.shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, size.height),
        [
          Color(0xffeeeeee),
          Color(0xff666666),
        ],
    );
    canvas.drawPath(path, paint);

    paint = Paint();
    paint.style = PaintingStyle.stroke;
    paint.strokeJoin = StrokeJoin.round;
    paint.strokeCap = StrokeCap.round;
    paint.color = Color(0xff666666);
    paint.shader = null;
    paint.strokeWidth = 1;
    canvas.drawPath(path, paint);

    {
      paint.strokeWidth = 2;
      Path path = Path();
      path.moveTo(1, -0);
      path.lineTo(size.width + 0, -0);
      path.lineTo(size.width + 0, size.height - 1);
      canvas.drawPath(path, paint);
    }

    {
      paint = Paint();
      paint.style = PaintingStyle.fill;
      paint.color = Color(0xffaaaaaa);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _FavKey extends GlobalObjectKey {
  _FavKey(value) : super(value);
}

class FavoriteItem extends StatefulWidget {
  final VoidCallback onTap;
  final FavCheckItem item;
  final Animation<double> animation;
  final VoidCallback onDismiss;
  final VoidCallback onMoveToFirst;

  FavoriteItem({
    Key key,
    this.onTap,
    this.item,
    this.animation,
    this.onDismiss,
    this.onMoveToFirst,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FavoriteItemState();
}

class _FavoriteItemState extends State<FavoriteItem> {

  bool highlight;
  GlobalKey _itemKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // return SizeTransition(
    //   sizeFactor: widget.animation,
    //   child: Dismissible(
    //     key: ObjectKey(widget.item),
    //     background: Container(color: Colors.red,),
    //     child: Column(
    //       children: [
    //         ListTile(
    //           title: Text(title),
    //           subtitle: Text(subtitle),
    //           leading: Image(
    //             image: NeoImageProvider(
    //               uri: Uri.parse(picture),
    //               cacheManager: NeoCacheManager.defaultManager,
    //             ),
    //             fit: BoxFit.cover,
    //             width: 56,
    //             height: 56,
    //             gaplessPlayback: true,
    //           ),
    //           onTap: () {
    //             setState(() {
    //               widget.onTap();
    //             });
    //           },
    //           trailing: widget.item.hasNew ? Icon(Icons.fiber_new, color: Colors.red,) : null,
    //         ),
    //         Divider(height: 1,)
    //       ],
    //     ),
    //     onDismissed: (direction) {
    //       widget.onDismiss?.call();
    //     },
    //   ),
    // );

    return InkWell(
      child: Container(
        padding: EdgeInsets.all(14),
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Container(
              width: _containerSize.width,
              height: _containerSize.height,
              key: _itemKey,
              decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor,
                      offset: Offset(6, 6),
                      blurRadius: 6
                    ),
                  ]
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      size: _containerSize,
                      painter: BookFramePainter(),
                      child: Image(
                        image: NeoImageProvider(
                          uri: Uri.parse(widget.item.item.picture),
                          cacheManager: NeoCacheManager.defaultManager,
                        ),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        width: _containerSize.width,
                        height: _containerSize.height,
                        errorBuilder: (context, e, stack) {
                          return Container(
                            color: Colors.grey,
                            child: Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: -1,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        boxShadow: [
                          BoxShadow(
                              offset: Offset(0, 1)
                          )
                        ]
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.item.item.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Padding(padding: EdgeInsets.only(top: 2)),
                          Text(
                            "[${widget.item.attachment.last?.isNotEmpty == true ? widget.item.attachment.last : widget.item.item.subtitle}]",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: widget.item.hasNew,
                    child: Positioned(
                      top: -6,
                      right: 5,
                      child: DecoratedIcon(
                        Icons.bookmark_sharp,
                        color: Colors.red,
                        size: 36,
                        shadows: [
                          BoxShadow(
                              offset: Offset(1, 1)
                          )
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: widget.item.value,
                    child: Positioned.fill(
                      child: Container(
                        color: Colors.black12,
                        child: SpinKitFadingCircle(
                          size: 36,
                          color: Colors.white,
                        ),
                      )
                    ),
                  ),
                ],
              ),
            ),
          )
        ),
      ),
      onTap: widget.onTap,
      onLongPress: () async {
        var renderObject = _itemKey.currentContext?.findRenderObject();
        if (renderObject != null) {
          var rect = renderObject.semanticBounds;
          var transform = renderObject.getTransformTo(null);
          Offset point = rect.center;
          var res = transform.applyToVector3Array([point.dx, point.dy, 0]);
          var ret = await showMenu<int>(
            context: context,
            position: RelativeRect.fromLTRB(
              res[0] - 20,
              res[1],
              res[0],
              res[1] + 20,
            ),
            items: [
              PopupMenuItem(
                child: Text('move_to_first'),
                value: 0,
              ),
              PopupMenuItem(
                child: Text('remove'),
                value: 1,
              ),
            ],
          );
          if (ret != null) {
            switch (ret) {
              case 0: {
                widget.onMoveToFirst?.call();
                break;
              }
              case 1: {
                widget.onDismiss?.call();
                break;
              }
            }
          }
        }
      },
    );
  }

  onStateChanged() {
    setState(() { });
  }

  @override
  void initState() {
    super.initState();
    widget.item.newListenable.addListener(onStateChanged);
    widget.item.addListener(_loadingUpdate);
  }

  @override
  void dispose() {
    super.dispose();
    widget.item.newListenable.removeListener(onStateChanged);
    widget.item.removeListener(_loadingUpdate);
  }

  @override
  void didUpdateWidget(FavoriteItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      oldWidget.item.newListenable.removeListener(onStateChanged);
      oldWidget.item.removeListener(_loadingUpdate);

      widget.item.newListenable.addListener(onStateChanged);
      widget.item.addListener(_loadingUpdate);
    }
  }

  void _loadingUpdate() {
    setState(() {});
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
  List<FavCheckItem> get items => FavoritesManager().items;
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

      var result = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(kt("confirm")),
            content: Text(kt("delete_item_2").replaceAll("{0}", item.item.title)),
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
    setState(() {
      FavoritesManager().remove(item);
    });
  }

  Widget buildGridView(BuildContext context) {
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
                  item: item,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(kt("favorites")),
        actions: buildActions(context),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white,
        ),
      ),
      body: items.length > 0 ? buildGridView(context) : NoData(),
    );
  }

  @override
  void initState() {
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
         // AppStatusNotification().dispatch(context);
      });
    }

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