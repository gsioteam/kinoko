
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glib/main/models.dart';
import 'package:kinoko/localizations/localizations.dart';
import 'package:kinoko/pages/favorites_page.dart';

import '../configs.dart';
import '../widgets/instructions_dialog.dart';
import 'imported_page.dart';

class FavHomePage extends StatefulWidget {

  FavHomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FavHomePageState();
}

class _FavHomePageState extends State<FavHomePage> with SingleTickerProviderStateMixin {
  late TabController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kt("favorites")),
        actions: buildActions(context),
        bottom: PreferredSize(
          child: TabBar(
            controller: controller,
            tabs: [
              Tab(
                text: kt("favorites"),
              ),
              Tab(
                text: kt("imported"),
              ),
            ],
          ),
          preferredSize: Size(double.infinity, 36),
        ),
      ),

      body: TabBarView(
        controller: controller,
        children: [
          FavoritesPage(),
          ImportedPage(),
        ]
      ),
    );
  }

  final GlobalKey iconKey = GlobalKey();

  List<Widget> buildActions(BuildContext context,) {
    bool has = KeyValue.get("$viewed_key:fav") == "true";
    return [
      IconButton(
        key: iconKey,
        onPressed: () {
          showInstructionsDialog(context, 'assets/fav',
            entry: kt('lang'),
          );
        },
        icon: Icon(Icons.help_outline),
        color: has ? AppBarTheme.of(context).iconTheme?.color ?? IconTheme.of(context).color : Colors.transparent,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 2, vsync: this);

    if (KeyValue.get("$viewed_key:fav") != "true") {
      Future.delayed(Duration(milliseconds: 300)).then((value) async {
        await showInstructionsDialog(context, 'assets/fav',
            entry: kt('lang'),
            onPop: () async {
              final renderObject = iconKey.currentContext?.findRenderObject();
              Rect? rect = renderObject?.paintBounds;
              var translation = renderObject?.getTransformTo(null).getTranslation();
              if (rect != null && translation != null) {
                return rect.shift(Offset(translation.x, translation.y));
              }
              return Rect.zero;
            }
        );
        KeyValue.set("$viewed_key:fav", "true");
        setState(() {
        });
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}