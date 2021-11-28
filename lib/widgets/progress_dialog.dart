

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:math';
import '../localizations/localizations.dart';

class ProgressValue {
  ProgressStatus status;
  String label;

  ProgressValue({
    this.status = ProgressStatus.Running,
    required this.label,
  });

  ProgressValue copyWith({
    ProgressStatus? status,
    String? label,
  }) {
    return ProgressValue(
      label: label??this.label,
      status: status??this.status,
    );
  }
}

class ProgressItem extends ValueNotifier<ProgressValue> {
  VoidCallback? onCancel;

  ProgressItem(ProgressValue value, [this.onCancel]) : super(value);
}

typedef ProgressRunCallback = ProgressItem Function();

class ProgressDialog extends StatefulWidget {
  final String title;
  final ProgressRunCallback run;

  ProgressDialog({
    required this.title,
    required this.run
  });

  @override
  State<StatefulWidget> createState() => _ProgressDialogState();

}

enum ProgressStatus {
  Running,
  Success,
  Failed
}

class _ProgressDialogState extends State<ProgressDialog> {
  ProgressItem? currentItem;

  bool get cancelable => currentItem?.onCancel != null;
  
  onCancel() {
    if (cancelable) {
      currentItem?.onCancel?.call();
      setState(() {
        currentItem?.dispose();
        currentItem = null;
      });
    }
  }

  onRetry() {
    setState(() {
      currentItem = widget.run();
      currentItem!.addListener(_update);
    });
  }

  Widget? bottomButtons() {
    switch (currentItem?.value.status) {
      case ProgressStatus.Running: {
        return MaterialButton(
          textColor: Theme.of(context).primaryColor,
          onPressed: currentItem?.onCancel != null ? onCancel : null,
          child: Text(kt("cancel")),
        );
      }
      case ProgressStatus.Failed: {
        if (currentItem?.onCancel != null) {
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
                onPressed: () {
                  Navigator.of(context).pop(ProgressStatus.Failed);
                },
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
      case ProgressStatus.Success: {
        return Container();
      }
      default: {

      }
    }
    return null;
  }

  Widget? makeIcon() {
    switch (currentItem?.value.status) {
      case ProgressStatus.Running: {
        return SpinKitRing(
          lineWidth: 4,
          size: 36,
          color: Theme.of(context).primaryColor,
        );
      }
      case ProgressStatus.Failed: {
        return Icon(
          Icons.error_outline,
          color: Theme.of(context).errorColor,
          size: 36,
        );
      }
      case ProgressStatus.Success: {
        return Icon(
          Icons.done,
          color: Theme.of(context).primaryColor,
          size: 36,
        );
      }
      default: {
        return SpinKitRing(
          lineWidth: 4,
          size: 36,
          color: Theme.of(context).primaryColor,
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
                        currentItem?.value.label ?? "...",
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
          ),
        ),
        onWillPop: () async {
          return false;
        });

  }

  @override
  void initState() {
    super.initState();
    currentItem = widget.run();
    currentItem!.addListener(_update);
  }

  @override
  void dispose() {
    super.dispose();
    currentItem?.dispose();
  }

  _update() {
    if (currentItem?.value.status == ProgressStatus.Success) {
      Future.delayed(Duration(seconds: 2)).then((value) {
        Navigator.of(context).pop(ProgressStatus.Success);
      });
    }
    setState(() {
    });
  }
}