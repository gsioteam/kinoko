
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glib/main/models.dart';
import 'package:kinoko/main.dart';
import 'package:kinoko/themes/them_desc.dart';
import '../configs.dart';
import '../localizations/localizations.dart';

class ThemeImage extends StatelessWidget {
  final ThemeDesc theme;

  ThemeImage({
    Key? key,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.data.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: Colors.black26
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 170,
        height: 224,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.data.appBarTheme.backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: theme.data.shadowColor,
                    offset: Offset(0, 0),
                    blurRadius: 2,
                  )
                ]
              ),
              height: 28,
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(
                      left: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.data.appBarTheme.iconTheme?.color,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    width: 10,
                    height: 10,
                  ),
                  Container(
                    margin: EdgeInsets.only(
                        left: 10
                    ),
                    decoration: BoxDecoration(
                      color: theme.data.appBarTheme.foregroundColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    height: 10,
                    width: 60,
                  )
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 2
                ),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 8
                      ),
                      decoration: BoxDecoration(
                        color: theme.data.textTheme.headline6?.color,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      height: 12,
                      width: 60,
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(
                          vertical: 3,
                          horizontal: 8
                      ),
                      decoration: BoxDecoration(
                        color: theme.data.textTheme.bodyText1?.color,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      height: 8,
                      width: 140,
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(
                          vertical: 3,
                          horizontal: 8
                      ),
                      decoration: BoxDecoration(
                        color: theme.data.textTheme.bodyText1?.color,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      height: 8,
                      width: 80,
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(
                          vertical: 3,
                          horizontal: 8
                      ),
                      decoration: BoxDecoration(
                        color: theme.data.textTheme.bodyText1?.color,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      height: 8,
                      width: 90,
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(
                          vertical: 3,
                          horizontal: 8
                      ),
                      decoration: BoxDecoration(
                        color: theme.data.textTheme.bodyText1?.color,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      height: 8,
                      width: 70,
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(
                          vertical: 3,
                          horizontal: 8
                      ),
                      decoration: BoxDecoration(
                        color: theme.data.textTheme.bodyText1?.color,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      height: 8,
                      width: 130,
                    ),
                  ],
                ),
              ),

            ),
            Material(
              color: theme.data.bottomNavigationBarTheme.backgroundColor,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: CircleAvatar(
                          backgroundColor: theme.data.disabledColor,
                          radius: 6,
                        )
                    ),
                    Expanded(
                        child: CircleAvatar(
                          backgroundColor: theme.data.primaryColor,
                          radius: 6,
                        )
                    ),
                    Expanded(
                        child: CircleAvatar(
                          backgroundColor: theme.data.primaryColor,
                          radius: 6,
                        )
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}


class ThemeWidget extends StatelessWidget {
  final bool selected;
  final ThemeDesc theme;
  final VoidCallback? onTap;

  ThemeWidget({
    Key? key,
    this.selected = false,
    required this.theme,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 7
      ),
      child: Material(
          color: themeData.canvasColor,
          shape: RoundedRectangleBorder(
              side: selected ? BorderSide(
                color: themeData.colorScheme.secondaryVariant,
                width: 3,
              ) : BorderSide.none,
              borderRadius: BorderRadius.circular(6)
          ),
          elevation: 3,
          shadowColor: themeData.shadowColor,
          child: InkWell(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: 18
                    ),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: ThemeImage(
                        theme: theme,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: 12
                  ),
                  child: Text(
                    kt(context, theme.title),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
            onTap: onTap,
          )
      ),
    );
  }
}

class ThemePage extends StatefulWidget {

  ThemePage({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ThemePageState();

}

class _ThemePageState extends State<ThemePage> {

  int themeIndex() {
    String label = KeyValue.get(theme_key);
    for (int i = 0, t = themes.length; i < t; ++i) {
      var theme = themes[i];
      if (theme.title == label) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    int current = themeIndex();
    var style = Theme.of(context).appBarTheme.systemOverlayStyle!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
        child: Scaffold(
          appBar: AppBar(
            title: Text(kt('theme')),
          ),
          body: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: themes.length,
              itemBuilder: (context, index) {
                var theme = themes[index];
                return ThemeWidget(
                  theme: theme,
                  selected: index == current,
                  onTap: () {
                    if (index != current) {
                      var theme = themes[index];
                      setState(() {
                        KeyValue.set(theme_key, theme.title);
                      });
                      ThemeChangedNotification(theme.data).dispatch(context);
                    }
                    // MemoryData().themeName = theme.name;
                    // PrettyThemeNotification(theme).dispatch(context);
                  },
                );
              }
          ),
        ),
        value: SystemUiOverlayStyle(
          systemNavigationBarColor: style.systemNavigationBarColor,
          systemNavigationBarIconBrightness: style.systemNavigationBarIconBrightness,
        ),
    );
  }
}