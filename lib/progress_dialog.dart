

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:math';
import 'localizations/localizations.dart';

abstract class ProgressItem {
  String defaultText = "";
  bool cancelable = true;
  void Function(String) onProgress;
  void Function() onComplete;
  void Function(String) onFail;

  void cancel();
  void progress(String text) {
    if (onProgress != null) onProgress(text);
    else print("Warring onProgress is null");
  }

  void complete() {
    if (onComplete != null) onComplete();
    else print("Warring onComplete is null");
  }

  void fail(String msg) {
    if (onFail != null) onFail(msg);
    else print("Warring onFail is null");
  }

  void retry() {

  }
}

class ProgressDialog extends StatefulWidget {
  final String title;
  final ProgressItem item;

  ProgressDialog({
    this.title,
    this.item
  });

  @override
  State<StatefulWidget> createState() {
    return _ProgressDialogState(item);
  }

}

enum _Status {
  Progress,
  Done,
  Failed
}

enum ProgressResult {
  Success,
  Failed
}

class _ProgressDialogState extends State<ProgressDialog> {
  String processText;
  _Status status;

  _ProgressDialogState(ProgressItem item) {
    processText = item.defaultText;
    status = _Status.Progress;
    item.onProgress = (String text) {
      this.setState(() {processText = text;});
    };
    item.onComplete = () {
      status = _Status.Done;
      Navigator.of(context).pop(ProgressResult.Success);
    };
    item.onFail = (String msg) {
      this.setState(() {
        status = _Status.Failed;
        processText = msg;
      });
    };

  }
  
  onCancel() {
    if (widget.item.cancelable) {
      widget.item.cancel();
      Navigator.of(context).pop(ProgressResult.Failed);
    }
  }

  onRetry() {
    widget.item.retry();
    setState(() {
      processText = widget.item.defaultText;
      status = _Status.Progress;
    });
  }

  Widget bottomButtons() {

    switch (status) {
      case _Status.Progress: {
        return MaterialButton(
          textColor: Theme.of(context).primaryColor,
          onPressed: widget.item.cancelable ? onCancel : null,
          child: Text(kt("cancel")),
        );
      }
      case _Status.Failed: {
        if (widget.item.cancelable) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MaterialButton(
                textColor: Theme.of(context).primaryColor,
                onPressed: onRetry,
                child: Text(kt("retry")),
              ),
              MaterialButton(
                textColor: Theme.of(context).primaryColor,
                onPressed: onCancel,
                child: Text(kt("cancel")),
              )
            ],
          );
        } else {
          return MaterialButton(
            textColor: Theme.of(context).primaryColor,
            onPressed: onRetry,
            child: Text(kt("retry")),
          );
        }
        break;
      }
      case _Status.Done: {
        return Container();
      }
    }
    return null;
  }

  Widget makeIcon() {
    switch (status) {
      case _Status.Progress: {
        return SpinKitRing(
          lineWidth: 4,
          size: 36,
          color: Theme.of(context).primaryColor,
        );
      }
      case _Status.Failed: {
        return Icon(
          Icons.error_outline,
          color: Theme.of(context).errorColor,
          size: 36,
        );
      }
      case _Status.Done: {
        return Icon(
          Icons.done,
          color: Theme.of(context).primaryColor,
          size: 36,
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    double c_width = MediaQuery.of(context).size.width*0.6;
    return WillPopScope(
        child: Dialog(
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      this.widget.title,
                      style: Theme.of(context).textTheme.headline6,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 36,
                        height: 36,
                        child: makeIcon(),
                      ),
                      Container(
                        padding: EdgeInsets.only(left: 8),
                        width: min(c_width, 260),
                        child: Text(
                          processText,
                          softWrap: true,
                        ),
                      )
                    ],
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    child: bottomButtons(),
                  )
                ],
              ),
            )
        ),
        onWillPop: (){
          return SynchronousFuture(widget.item.cancelable);
        });

  }

}