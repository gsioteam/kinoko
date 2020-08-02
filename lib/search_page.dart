
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:kinoko/book_list.dart';
import 'package:kinoko/widgets/better_refresh_indicator.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/project.dart';
import 'package:glib/main/context.dart';
import 'localizations/localizations.dart';

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
  TextEditingController textController = TextEditingController();
  bool showClear = false;

  _SearchPageState();

  search() {
    widget.context.reload({
      "key": textController.text
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Stack(
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                hintText: kt("search"),
                border: InputBorder.none,
              ),
              controller: textController,
              onChanged: (text) {
                if (text.isEmpty && showClear) {
                  setState(() {
                    showClear = false;
                  });
                } else if (text.isNotEmpty && !showClear) {
                  setState(() {
                    showClear = true;
                  });
                }
              },
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
      ),
      body: BookListPage(widget.project, widget.context),
    );
  }

  @override
  void initState() {
    widget.context.control();
    super.initState();
  }

  @override
  void dispose() {
    widget.context.release();
    super.dispose();
  }
}