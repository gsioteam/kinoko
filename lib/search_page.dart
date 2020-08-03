
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:glib/core/array.dart';
import 'package:kinoko/book_list.dart';
import 'package:kinoko/widgets/better_refresh_indicator.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/project.dart';
import 'package:glib/main/context.dart';
import 'localizations/localizations.dart';

class _RectClipper extends CustomClipper<Rect> {

  double value;

  _RectClipper(this.value);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width, size.height * this.value);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return !(oldClipper is _RectClipper) || (oldClipper as _RectClipper).value != value;
  }
}

class AnimatedExtend extends StatefulWidget {

  Widget child;
  bool display;
  Curve curve;
  Curve reverseCurve;
  Duration duration;

  AnimatedExtend({
    Key key,
    @required this.child,
    this.display = false,
    this.curve = Curves.linear,
    this.reverseCurve = Curves.linear,
    this.duration = const Duration(milliseconds: 300)
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AnimatedExtendState();

}

class _AnimatedExtendState extends State<AnimatedExtend> with SingleTickerProviderStateMixin {
  Animation<double> _animation;
  Animation<double> get animation => _animation;
  AnimationController _controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: widget.child,
      builder: (context, child) {
        return ClipRect(
          clipper: _RectClipper(animation.value),
          child: child,
        );
      },
    );
  }
  
  _updateAnimation() {
    if (widget.curve == null && widget.reverseCurve == null) {
      _animation = _controller;
    } else {
      _animation = CurvedAnimation(parent: _controller, curve: widget.curve, reverseCurve: widget.reverseCurve);
    }
  }

  @override
  void didUpdateWidget(AnimatedExtend oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.curve != widget.curve || oldWidget.reverseCurve != widget.reverseCurve) {
      _updateAnimation();
    }
    _controller.duration = _controller.reverseDuration = widget.duration;
    if (oldWidget.display != widget.display) {
      if (widget.display) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration
    );
    _updateAnimation();
    super.initState();
  }

}

class SearchPage extends StatefulWidget {

  Project project;
  Context context;

  SearchPage(this.project, this.context);

  @override
  State<StatefulWidget> createState() {
    return _SearchPageState();
  }

}

class _SearchPageState extends State<SearchPage> {
  TextEditingController textController;
  bool showClear = false;
  FocusNode focusNode;
  List<String> searchHits = [];
  GlobalKey<AnimatedListState> _listKey = GlobalKey();

  _SearchPageState();

  search() {
    setState(() {
      focusNode.unfocus();
    });
    if (textController.text.isNotEmpty) {
      widget.context.reload({
        "key": textController.text
      });
    }
  }

  updateSearchHit(text) {
    Array keys = Context.searchKeys(text, 10);
    for (int i = 0, t = searchHits.length; i < t; ++i) {
      _listKey.currentState?.removeItem(0, (context, animation) => animatedItem(searchHits[i], animation, true), duration: Duration(milliseconds: 0));
    }
    searchHits.clear();
    for (int i = 0, t = keys.length; i < t; ++i) {
      String key = keys[i];
      searchHits.add(key);
      _listKey.currentState?.insertItem(i, duration: Duration(milliseconds: 0));
    }
  }

  Widget animatedItem(String key, Animation<double> animation, bool removing) {
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
        title: Text(key, style: Theme.of(context).textTheme.bodyText2.copyWith(color: Colors.black54),),
        leading: Icon(Icons.history),
        trailing: IconButton(
            icon: Icon(Icons.clear),
            onPressed: removing ? null : () {

            }
        ),
        onTap: removing ? null : () {
          textController.text = key;
          search();
        },
      ),
    );
  }

  onChange(text) {
    if (text.isEmpty && showClear) {
      setState(() {
        showClear = false;
      });
    } else if (text.isNotEmpty && !showClear) {
      setState(() {
        showClear = true;
      });
    }
    if (focusNode.hasFocus) {
      updateSearchHit(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: Stack(
            children: <Widget>[
              TextField(
                decoration: InputDecoration(
                  hintText: kt("search"),
                  border: InputBorder.none,
                ),
                controller: textController,
                autofocus: true,
                focusNode: focusNode,
                onChanged: onChange,
                onSubmitted: (text) {
                  search();
                },
              ),
              Positioned(
                  right: 0,
                  child: AnimatedCrossFade(
                      firstChild: Container(
                        width: 0,
                        height: 0,
                      ),
                      secondChild: IconButton(
                        icon: Icon(Icons.clear),
                        color: Colors.black38,
                        onPressed: () {
                          textController.clear();
                          setState(() {
                            showClear = false;
                          });
                        }
                      ),
                      crossFadeState: showClear ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: Duration(milliseconds: 300)
                  )
              ),
            ],
          ),
          backgroundColor: Colors.white,
          iconTheme: Theme.of(context).iconTheme.copyWith(color: Colors.black87),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.search),
              onPressed: search
            ),
          ],
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              if (focusNode.hasFocus) {
                focusNode.unfocus();
              } else {
                Navigator.of(context).pop();
              }
            }
          ),
        ),
        body: Stack(
          children: <Widget>[
            BookListPage(widget.project, widget.context),
            AnimatedExtend(
              child: Container(
                color: Colors.white,
                child: AnimatedList(
                  key: _listKey,
                  itemBuilder: (context, index, Animation<double> animation) {
                    return animatedItem(searchHits[index], animation, false);
                  },
                  initialItemCount: searchHits.length,
                ),
              ),
              display: focusNode.hasFocus,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
      onWillPop: () async {
        if (focusNode.hasFocus) {
          focusNode.unfocus();
          return false;
        } else {
          return true;
        }
      }
    );
  }

  @override
  void initState() {
    widget.context.control();
    textController = TextEditingController();
    focusNode = FocusNode();
    focusNode.addListener(() {
      setState(() {updateSearchHit(textController.text);});
    });
    super.initState();
  }

  @override
  void dispose() {
    widget.context.release();
    focusNode.dispose();
    textController.dispose();
    super.dispose();
  }
}