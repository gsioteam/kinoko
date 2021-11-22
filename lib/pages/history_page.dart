
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kinoko/utils/book_info.dart';
import 'package:kinoko/utils/history_manager.dart';
import 'package:kinoko/utils/js_extensions.dart';
import 'package:kinoko/utils/plugin/plugin.dart';
import 'package:kinoko/utils/plugins_manager.dart';
import 'package:kinoko/widgets/no_data.dart';
import '../configs.dart';
import '../localizations/localizations.dart';

import 'picture_viewer.dart';
import '../utils/neo_cache_manager.dart';

class HistoryPage extends StatefulWidget {
  HistoryPage({Key? key}) : super(key: key, );

  @override
  State<StatefulWidget> createState() => _HistoryPageState();

}

class _HistoryPageState extends State<HistoryPage> {

  void onChange() async {
    await Future.delayed(Duration(milliseconds: 100));
    setState(() { });
  }

  @override
  void initState() {
    super.initState();
    HistoryManager().items.addListener(onChange);
  }

  @override
  void dispose() {
    super.dispose();
    HistoryManager().items.removeListener(onChange);
  }

  @override
  Widget build(BuildContext context) {
    List<HistoryItem> items = HistoryManager().items.data;

    return Scaffold(
      appBar: AppBar(
        title: Text(kt("history")),
        actions: [
          IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: () async {
                bool? ret = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(kt("confirm")),
                        content: Text(kt("clear_history")),
                        actions: [
                          TextButton(
                            child: Text(kt("no")),
                            onPressed: ()=> Navigator.of(context).pop(false),
                          ),
                          TextButton(
                            child: Text(kt("yes")),
                            onPressed:()=> Navigator.of(context).pop(true),
                          ),
                        ],
                      );
                    }
                );
                if (ret == true)
                  HistoryManager().clear();
              }
          )
        ],
      ),
      body: items.length > 0 ? ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          HistoryItem item = items[index];
          BookInfo info = item.info;
          return ListTile(
            tileColor: Theme.of(context).colorScheme.surface,
            title: Text(info.title),
            subtitle: Text(info.subtitle ?? ""),
            leading: info.picture == null ? Container(
              width: 56,
              height: 56,
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Icon(
                  Icons.broken_image,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ) : Image(
              image: NeoImageProvider(
                  uri: Uri.parse(info.picture!),
                  cacheManager: NeoCacheManager.defaultManager
              ),
              fit: BoxFit.cover,
              width: 56,
              height: 56,
              gaplessPlayback: true,
            ),
            onTap: () {
              enterPage(item);
            },
          );
        },
      ) : NoData(),
    );

  }

  void enterPage(HistoryItem historyItem) async {
    Plugin? plugin = PluginsManager.instance.findPlugin(historyItem.pluginID);
    if (plugin?.isValidate == true) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return DApp(
          entry: historyItem.bookPage,
          fileSystems: [plugin!.fileSystem],
          classInfo: kiControllerInfo,
          controllerBuilder: (script, state) => KiController(script, plugin)..state = state,
          initializeData: historyItem.info.data,
          onInitialize: (script) {
            script.addClass(downloadManager);
            Configs.instance.setupJS(script, plugin);
          },
        );
      }));
    } else {
      Fluttertoast.showToast(msg: kt("no_project_found"));
    }
  }
}