
import 'package:flutter/widgets.dart';

class AppBarData {
  String title = "";
  List<Widget> Function(BuildContext context, void Function() changed) buildActions;

  AppBarData({this.title, this.buildActions});
}

abstract class HomeWidget extends StatefulWidget {

  final AppBarData _appBarData;
  final String title;

  HomeWidget({Key key, this.title, AppBarData appBarData}) : _appBarData = appBarData, super(key: key);

  AppBarData get appBarData {
    if (_appBarData == null){
      return AppBarData(
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