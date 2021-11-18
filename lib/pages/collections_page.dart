
import 'package:flutter/material.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kinoko/pages/libraries_page.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:kinoko/utils/book_info.dart';
import 'package:kinoko/utils/download_manager.dart';
import 'package:kinoko/utils/image_providers.dart';
import 'package:kinoko/utils/plugin/plugin.dart';
import 'package:flutter_dapp/src/controller.dart';
import 'package:kinoko/utils/plugin/utils.dart';
import '../localizations/localizations.dart';
import '../configs.dart';
import '../widgets/no_data.dart';
import 'ext_page.dart';
import 'picture_viewer.dart';
import 'source_page.dart';

const double _LogoSize = 24;

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
}

ClassInfo kiControllerInfo = controllerClass.inherit<KiController>(
  name: "_Controller",
  functions: {
    "openBook": JsFunction.ins((obj, argv) => obj.openBook(argv[0])),
    "openBrowser": JsFunction.ins((obj, argv) => obj.openBrowser(argv[0])),
    "addDownload": JsFunction.ins((obj, argv) => obj.addDownload(argv[0])),
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

class CollectionsPage extends StatefulWidget {
  CollectionsPage({Key? key}) :
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CollectionsPageState();
  }
}

class _CollectionsPageState extends State<CollectionsPage> {

  Plugin? plugin;

  List<GlobalKey> _keys = [];

  @override
  Widget build(BuildContext context) {

    List<Widget> actions = [];
    var extensions = plugin?.information?.extensions;

    if (extensions != null) {
      for (int i = 0, t = extensions.length; i < t; ++i) {
        var extension = extensions[i];
        if (_keys.length <= i) {
          _keys.add(GlobalKey());
        }
        GlobalKey key = _keys[i];
        actions.add(IconButton(
          key: key,
          icon: Icon(extension.getIconData()),
          onPressed: () {
            RenderObject? object = key.currentContext?.findRenderObject();
            var translation = object?.getTransformTo(null).getTranslation();
            var size = object?.semanticBounds.size;
            Offset center;
            if (translation != null) {
              double x = translation.x, y = translation.y;
              if (size != null) {
                x += size.width / 2;
                y += size.height / 2;
              }
              center = Offset(x, y);
            } else {
              center = Offset(0, 0);
            }

            Navigator.of(context).push(ExtPageRoute(
                center: center,
                builder: (context) {
                  return ExtPage(
                    plugin: plugin!,
                    entry: extension.index,
                  );
                }
            ));
          },
        ));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: _buildLogo(context),
        elevation: plugin?.information?.appBarElevation,
        actions: actions,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (plugin == null) {
      return Stack(
        children: [
          Positioned.fill(child: NoData()),
          Positioned(
              left: 18,
              top: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: DecoratedIcon(
                        Icons.arrow_upward,
                        color: Theme.of(context).disabledColor,
                        size: 16,
                        shadows: [
                          BoxShadow(
                              color: Theme.of(context).colorScheme.surface,
                              offset: Offset(1, 1)
                          ),
                        ]
                    ),
                  ),
                  Text(
                    kt('click_to_select'),
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).disabledColor,
                        shadows: [
                          Shadow(
                              color: Theme.of(context).colorScheme.surface,
                              offset: Offset(1, 1)
                          ),
                        ]
                    ),
                  )
                ],
              )
          ),
        ],
      );
    } else {
      String index = plugin!.information!.index;
      if (index[0] != '/') {
        index = '/' + index;
      }
      return DApp(
        entry: index,
        fileSystems: [plugin!.fileSystem],
        classInfo: kiControllerInfo,
        controllerBuilder: (script, state) => KiController(script, plugin!)..state = state,
        onInitialize: (script) {
          script.addClass(downloadManager);
          Configs.instance.setupJS(script, plugin!);
          // setupJS(script, plugin!);

          // script.global['openVideo'] = script.function((argv) {
          //   OpenVideoNotification(
          //       key: argv[0],
          //       data: jsValueToDart(argv[1]),
          //       plugin: plugin!
          //   ).dispatch(context);
          // });
        },
      );
    }
  }

  Widget _buildLogo(BuildContext context) {
    return InkWell(
      highlightColor: Theme.of(context).primaryColor,
      child: Container(
        height: 36,
        child: Row(
          children: [
            CircleAvatar(
              radius: _LogoSize / 2,
              backgroundColor: Theme.of(context).colorScheme.background,
              child: ClipOval(
                child: plugin == null ?
                Icon(
                  Icons.extension,
                  size: _LogoSize * 0.66,
                  color: Theme.of(context).colorScheme.onBackground,
                ) : pluginImage(
                  plugin,
                  width: _LogoSize,
                  height: _LogoSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, e, stack) {
                    return Container(
                      width: _LogoSize,
                      height: _LogoSize,
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Theme.of(context).colorScheme.onBackground,
                          size: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                child: Text(plugin?.information?.name ?? kt('select_project')),
              ),
            ),
          ],
        ),
      ),
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return LibrariesPage();
        }));
      },
    );
  }

  @override
  void initState() {
    super.initState();

    plugin = Configs.instance.current;
    Configs.instance.addListener(_update);
  }

  @override
  void dispose() {
    super.dispose();
    Configs.instance.removeListener(_update);
  }

  void _update() {
    setState(() {
      plugin = Configs.instance.current;
    });
  }
}