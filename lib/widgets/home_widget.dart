
import 'package:flutter/widgets.dart';

class AppBarData {
  String title = "";
  List<Widget> Function(BuildContext context, void Function() changed) buildActions;

  AppBarData({this.title, this.buildActions});
}

abstract class HomeWidget extends StatefulWidget {
  HomeWidget({Key key}):super(key: key);

  String title = "";


  AppBarData _appBarData;
  AppBarData get appBarData {
    if (_appBarData == null){
      _appBarData = AppBarData(
        title: this.title,
        buildActions: buildActions
      );
    }
    return _appBarData;
  }

  List<Widget> buildActions(BuildContext context, void Function() changed) {
    return [];
  }
}