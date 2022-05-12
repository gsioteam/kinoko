
import 'package:flutter/material.dart';
import 'package:kinoko/localizations/localizations.dart';
import 'package:kinoko/utils/image_providers.dart';
import 'package:kinoko/utils/plugin/plugin.dart';
import 'package:kinoko/utils/plugins_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import "package:flutter_localized_locales/flutter_localized_locales.dart";

class PluginDialog extends StatefulWidget {

  final PluginInfo pluginInfo;
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;

  PluginDialog({
    Key? key,
    required this.pluginInfo,
    this.title,
    this.content,
    this.actions,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PluginDialogState();
}

class _PluginDialogState extends State<PluginDialog> {
  late String _pluginID;

  @override
  Widget build(BuildContext context) {
    Plugin? plugin = PluginsManager.instance.findPlugin(_pluginID);

    String fullTitle = widget.pluginInfo.title;
    String? originTitle;
    String? languages;
    RegExp regExp = RegExp("^(\\w+)(\\([^\\)]+\\))?\$");
    var result = regExp.firstMatch(fullTitle);
    if (result != null) {
      originTitle = result.group(1);
      String? language = result.group(2);
      if (language != null) {
        var arr = language.substring(1, language.length - 1).split(',');
        languages = arr.map((e) => LocaleNames.of(context)!.nameOf(e.trim().toLowerCase())).join(", ");
      }
    }

    String title;
    Widget icon;
    if (plugin?.isValidate == true) {
      title = plugin!.information!.name;
      icon = pluginImage(
        plugin,
        width: 56,
        height: 56,
        errorBuilder: (context, e, stack) {
          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Color(0x1F999999),
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            child: Icon(
              Icons.broken_image,
              color: Colors.white,
            ),
          );
        },
      );
    } else {
      if (originTitle != null) {
        title = originTitle;
      } else {
        title = fullTitle;
      }
      icon = widget.pluginInfo.icon == null ? buildIdenticon(
        widget.pluginInfo.src,
        width: 56,
        height: 56,
      ) : Image(
        image: networkImageProvider(widget.pluginInfo.icon!),
        width: 56,
        height: 56,
      );
    }

    return AlertDialog(
      title: widget.title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.content != null) widget.content!,
          Container(
            padding: EdgeInsets.only(
              top: 10,
              left: 10,
              right: 10
            ),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.all(Radius.circular(4)),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 8
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    icon,
                    Padding(padding: EdgeInsets.only(left: 8)),
                    Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                            if (widget.pluginInfo.author != null) Padding(padding: EdgeInsets.only(top: 4)),
                            if (widget.pluginInfo.author != null) Text.rich(TextSpan(
                                children: [
                                  TextSpan(text: "${kt("author")}: ",),
                                  WidgetSpan(
                                    child: InkWell(
                                      child: Text(
                                        widget.pluginInfo.author!.name,
                                        style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            decoration: TextDecoration.underline
                                        ),
                                      ),
                                      onTap: () {
                                        launch(widget.pluginInfo.author!.url);
                                      },
                                    ),
                                  ),
                                ]
                            )),
                            if (languages != null) Padding(padding: EdgeInsets.only(top: 4)),
                            if (languages != null) Text.rich(TextSpan(
                              children: [
                                TextSpan(text: "${kt("sup_languages")}: \n"),
                                TextSpan(text: languages, style: TextStyle(
                                  color: Theme.of(context).primaryColor
                                )),
                              ]
                            )),
                          ],
                        )
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      actions: widget.actions,
    );
  }

  @override
  void initState() {
    super.initState();

    _pluginID = PluginsManager.instance.calculatePluginID(widget.pluginInfo.src);
  }
}