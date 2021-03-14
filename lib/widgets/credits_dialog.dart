
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import '../localizations/localizations.dart';

Future<bool> showCreditsDialog(BuildContext context) async {
  var kt = lc(context);
  String credits = kt("credits_content");
  RegExp exp = RegExp(r"https?:\/\/[^ \n]+");
  List<InlineSpan> children = [];
  var matches = exp.allMatches(credits);
  if (matches.length > 0) {
    int offset = 0;
    for (var match in matches) {
      String link = match.group(0);
      children.add(TextSpan(
          text: credits.substring(offset, match.start)
      ));
      children.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: IconButton(
              icon: Icon(Icons.open_in_new),
              color: Theme.of(context).primaryColor,
              onPressed: () async {
                if (await canLaunch(link)) {
                  await launch(link);
                } else {
                  await Fluttertoast.showToast(msg: kt("can_not_open").replaceFirst("{0}", link));
                }
              }
          )
      ));
      offset = match.end;
    }
    children.add(TextSpan(
        text: credits.substring(offset)
    ));
  } else {
    children.add(TextSpan(text: credits));
  }
  Text creditsContent = Text.rich(TextSpan(
      children: children
  ));

  return await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(padding: EdgeInsets.only(top: 10)),
                Container(
                  width: double.infinity,
                  height: math.min(MediaQuery.of(context).size.height * 0.6, 420),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: double.infinity,
                              child: Text(kt("disclaimer"), style: Theme.of(context).textTheme.headline6,),
                            ),
                            Padding(padding: EdgeInsets.only(top: 10)),
                            Text(kt("disclaimer_content"), style: Theme.of(context).textTheme.bodyText1,),
                            Padding(padding: EdgeInsets.only(top: 10)),
                            Container(
                              width: double.infinity,
                              child: Text(kt("credits"), style: Theme.of(context).textTheme.headline6,),
                            ),
                            Padding(padding: EdgeInsets.only(top: 10)),
                            Container(
                              width: double.infinity,
                              child: creditsContent,
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MaterialButton(
                      textColor: Theme.of(context).primaryColor,
                      child: Text(kt("ok")),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        );
      }
  );
}