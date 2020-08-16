

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:glib/main/data_item.dart';

Widget makeBookItem(BuildContext context, DataItem item, void Function() onTap) {
  if (item.type == DataItemType.Header) {
    return Container(
      padding: EdgeInsets.fromLTRB(5, 2, 5, 2),
      height: 30,
      child: Row(
        children: <Widget>[
          Image(
            image: CachedNetworkImageProvider(item.picture),
            width: 26,
            height: 26,
          ),
          Padding(padding: EdgeInsets.all(5)),
          Text(item.title, style: Theme.of(context).textTheme.subtitle1,)
        ],
      ),
    );
  } else {
    return ListTile(
      title: Text(item.title),
      subtitle: Text(item.subtitle),
      leading: Image(
        image: CachedNetworkImageProvider(item.picture),
        fit: BoxFit.cover,
        width: 56,
        height: 56,
      ),
      onTap: onTap,
    );
  }
}