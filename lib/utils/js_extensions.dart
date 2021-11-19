
import 'package:flutter/material.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:flutter_dapp/src/controller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kinoko/pages/picture_viewer.dart';
import 'package:kinoko/pages/source_page.dart';
import 'package:kinoko/utils/history_manager.dart';

import 'book_info.dart';
import 'download_manager.dart';
import 'favorites_manager.dart';
import 'plugin/plugin.dart';
import 'plugin/utils.dart';
import '../localizations/localizations.dart';

class KiController extends Controller {
  Plugin plugin;
  KiController(JsScript script, this.plugin) : super(script);

  openBook(JsValue data) {
    var d = jsValueToDart(data);
    return Navigator.of(state!.context).push(MaterialPageRoute(builder: (context) {
      return PictureViewer(
        plugin: plugin,
        list: d["list"],
        initializeIndex: d["index"],
      );
    }));
  }

  openBrowser(String url) {
    return Navigator.of(state!.context).push(MaterialPageRoute(builder: (context) {
      return SourcePage(
        url: url,
      );
    }));
  }

  addDownload(JsValue list) {
    int length = list["length"];
    for (int i = 0, t = length; i < t; ++i) {
      var data = list[i];
      DownloadManager().add(BookInfo.fromData(jsValueToDart(data)), plugin);
    }
    Fluttertoast.showToast(
        msg: lc(state!.context)("added_download").replaceFirst("{0}", length.toString())
    );
  }

  addFavorite(JsValue data, dynamic last) {
    var map = jsValueToDart(data);
    LastData? lastData;
    if (last is JsValue) {
      var map = jsValueToDart(last);
      lastData = LastData(
        name: map["title"],
        key: map["key"],
        updateTime: DateTime.now(),
      );
    }
    FavoritesManager().add(
        plugin,
        BookInfo.fromData(map),
        map["page"],
        lastData);
  }

  addHistory(JsValue data) {
    var map = jsValueToDart(data);
    HistoryManager().insert(
      BookInfo.fromData(map),
      map["page"],
      plugin
    );
  }
}

ClassInfo kiControllerInfo = controllerClass.inherit<KiController>(
    name: "_Controller",
    functions: {
      "openBook": JsFunction.ins((obj, argv) => obj.openBook(argv[0])),
      "openBrowser": JsFunction.ins((obj, argv) => obj.openBrowser(argv[0])),
      "addDownload": JsFunction.ins((obj, argv) => obj.addDownload(argv[0])),
      "addFavorite": JsFunction.ins((obj, argv) => obj.addFavorite(argv[0], argv[1])),
      "addHistory": JsFunction.ins((obj, argv) => obj.addHistory(argv[0])),
    }
);

ClassInfo downloadManager = ClassInfo(
    name: "DownloadManager",
    newInstance: (_, __) => throw Exception(),
    functions: {
      "exist": JsFunction.sta((argv) => DownloadManager().exist(argv[0])),
      "remove": JsFunction.sta((argv) => DownloadManager().removeKey(argv[0])),
    }
);

ClassInfo favoriteManager = ClassInfo(
    name: "FavoritesManager",
    newInstance: (_, __) => throw Exception(),
    functions: {
      "exist": JsFunction.sta((argv) => FavoritesManager().exist(argv[0])),
      "remove": JsFunction.sta((argv) => FavoritesManager().remove(argv[0])),
    }
);