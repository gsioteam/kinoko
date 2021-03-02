
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../localizations/localizations.dart';

Future<void> showInstructionsDialog(BuildContext context, String content) {
  var kt = lc(context);
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(kt("instructions")),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {

            },
            child: Text(kt("ok"))
          ),
        ],
      );
    }
  );
}