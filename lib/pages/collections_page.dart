
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:kinoko/pages/libraries_page.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:kinoko/utils/image_providers.dart';
import 'package:kinoko/utils/js_extensions.dart';
import 'package:kinoko/utils/plugin/plugin.dart';
import 'package:kinoko/utils/plugins_manager.dart';
import '../localizations/localizations.dart';
import '../configs.dart';
import '../widgets/no_data.dart';
import 'ext_page.dart';

const double _LogoSize = 24;

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
      var systemOverlayStyle = Theme.of(context).appBarTheme.systemOverlayStyle;
      return DApp(
        entry: index,
        fileSystems: [plugin!.fileSystem],
        classInfo: kiControllerInfo,
        controllerBuilder: (script, state) => KiController(script, plugin!)..state = state,
        onInitialize: (script) {
          script.addClass(downloadManager);
          Configs.instance.setupJS(script, plugin!);
        },
        onNavigateTo: ({
          JsScript? script,
          String? file,
          dynamic initializeData,
          DAppCustomer? customerMethods,
        }) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            child: DWidget(
              script: script!,
              file: file!,
              initializeData: initializeData,
              customerMethods: customerMethods!,
            ),
            value: systemOverlayStyle!,
          );
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

    plugin = PluginsManager.instance.current;
    PluginsManager.instance.addListener(_update);
  }

  @override
  void dispose() {
    super.dispose();
    PluginsManager.instance.removeListener(_update);
  }

  void _update() {
    setState(() {
      plugin = PluginsManager.instance.current;
    });
  }
}