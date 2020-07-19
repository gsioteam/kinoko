
import 'dart:ui';

import 'package:cache_image/cache_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glib/main/data_item.dart';
import 'package:kinoko/localizations/localizations.dart';

class BookPage extends StatefulWidget {

  DataItem data;

  BookPage(this.data);

  @override
  State<StatefulWidget> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {

  DataItem get data => widget.data;

  Widget createItem(BuildContext context, int idx) {
    return ListTile(
      title: Text("Test $idx"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            expandedHeight: 288.0,
            bottom: PreferredSize(
                child: Container(
                  height: 48,
                  color: Colors.white,
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: Row(
                    children: <Widget>[
                      Text(kt("chapters")),
                      Expanded(child: Container()),
                      IconButton(
                          icon: Icon(Icons.sort),
                          color: Theme.of(context).primaryColor,
                          onPressed: (){}
                      ),
                      IconButton(
                          icon: Icon(Icons.file_download),
                          color: Theme.of(context).primaryColor,
                          onPressed: (){}
                      ),
                    ],
                  ),
                ),
                preferredSize: Size(double.infinity, 48)
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: data.title,
                      style: Theme.of(context).textTheme.headline2.copyWith(color: Colors.white, fontSize: 14),
                    ),
                    WidgetSpan(child: Padding(padding: EdgeInsets.only(top: 5),)),
                    TextSpan(
                      text: "\nSummary Summary Summary Summary Summary Summary Summary Summary Summary",
                      style: Theme.of(context).textTheme.bodyText2.copyWith(color: Colors.white, fontSize: 8),
                    )
                  ]
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              titlePadding: EdgeInsets.only(left: 20, bottom: 64),
              background: Stack(
                children: <Widget>[
                  Image(
                    width: double.infinity,
                    height: double.infinity,
                    image: CacheImage(data.picture),
                    fit: BoxFit.cover,
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX:  4, sigmaY: 4),
                    child: Container(
                      color: Colors.black.withOpacity(0),
                    ),
                  ),
                  Container(
                    alignment: Alignment.bottomLeft,
                    width: double.infinity,
                    height: double.infinity,
                    padding: EdgeInsets.fromLTRB(14, 10, 14, 58),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color.fromRGBO(0, 0, 0, 0), Color.fromRGBO(0, 0, 0, 0.5)],
                        stops: [0.4, 1]
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.favorite),
                onPressed: (){}
              ),
            ],
          ),
          SliverList(
              delegate: SliverChildBuilderDelegate(createItem,
                childCount: 90,
              ),
          )
        ],
      ),
    );
  }

//  Column(
//        mainAxisSize: MainAxisSize.max,
//        children: <Widget>[
//          Container(
//            height: 240,
//            child: Stack(
//              children: <Widget>[
//                Image(
//                  image: CacheImage(data.picture),
//                  fit: BoxFit.cover,
//                  width: double.infinity,
//                  height: double.infinity,
//                ),
//                BackdropFilter(
//                  filter: ImageFilter.blur(sigmaX:  4, sigmaY: 4),
//                  child: Container(
//                    color: Colors.black.withOpacity(0),
//                  ),
//                ),
//                Container(
//                  alignment: Alignment.bottomLeft,
//                  width: double.infinity,
//                  height: double.infinity,
//                  padding: EdgeInsets.fromLTRB(14, 10, 14, 10),
//                  decoration: BoxDecoration(
//                    gradient: LinearGradient(
//                        begin: Alignment.topCenter,
//                        end: Alignment.bottomCenter, // 10% of the width, so there are ten blinds.
//                        colors: [Color.fromRGBO(0, 0, 0, 0), Color.fromRGBO(0, 0, 0, 0.5)], // whitish to gray
//                        stops: [0.4, 1]
//                    ),
//                  ),
//                  child: Column(
//                    mainAxisSize: MainAxisSize.min,
//                    crossAxisAlignment: CrossAxisAlignment.start,
//                    children: <Widget>[
//                      Text("Title",
//                        style: Theme.of(context).textTheme.headline5.copyWith(
//                          color: Colors.white,
////                          shadows: [Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2)]
//                        ),
//                      ),
//                      Padding(padding: EdgeInsets.only(top: 5)),
//                      Text("summary summary summary summary summary summary summary summary summary",
//                        overflow: TextOverflow.ellipsis,
//                        style: Theme.of(context).textTheme.bodyText2.copyWith(
//                          color: Colors.white,
////                          shadows: [Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2)]
//                        ),
//                      )
//                    ],
//                  ),
//                ),
//                SafeArea(
//                    child: Container(
//                      width: double.infinity,
//                      height: 44,
//                      padding: EdgeInsets.only(
//                          left: 10,
//                          right: 10
//                      ),
//                      child: Row(
//                        children: <Widget>[
//                          CircleAvatar(
//                            backgroundColor: Color.fromRGBO(0xff, 0xff, 0xff, 0.8),
//                            child: IconButton(
//                                icon: Icon(Icons.arrow_back),
//                                onPressed: () {
//                                  Navigator.of(context).pop();
//                                }
//                            ),
//                          ),
//                          Expanded(child: Container()),
//                          CircleAvatar(
//                            backgroundColor: Color.fromRGBO(0xff, 0xff, 0xff, 0.8),
//                            foregroundColor: Colors.grey,
//                            child: IconButton(
//                                icon: Icon(Icons.favorite),
//                                onPressed: () {
//                                }
//                            ),
//                          )
//                        ],
//                      ),
//                    )
//                )
//              ],
//            ),
//          ),
//
//          Expanded(
//              child: Column(
//                children: <Widget>[
//                  Row(
//                    children: <Widget>[
//                      Expanded(child: Container()),
//                      IconButton(
//                          color: Theme.of(context).primaryColor,
//                          icon: Icon(Icons.sort),
//                          onPressed: (){}
//                      ),
//                      IconButton(
//                          color: Theme.of(context).primaryColor,
//                          icon: Icon(Icons.file_download),
//                          onPressed: (){}
//                      ),
//                    ],
//                  ),
//                  Expanded(
//                      child: ListView.separated(
//                        padding: EdgeInsets.all(0),
//                          itemBuilder: (context, idx) {
//                            return ListTile(
//                              title: Text("Test $idx"),
//                            );
//                          },
//                          separatorBuilder: (context, idx) => Divider(),
//                          itemCount: 90
//                      )
//                  )
//                ],
//              )
//          )
//        ],
//      )
}