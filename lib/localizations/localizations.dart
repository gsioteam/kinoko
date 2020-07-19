

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'zh_hans.dart' as zhHans;

class KinokoLocalizations {
  Map words;
  Map total_words;
  KinokoLocalizations(this.words, this.total_words);

  String get(String key) {
    if (words.containsKey(key)) return words[key];
    var txt = total_words[key];
    if (txt == null) txt = key;
    return txt;
  }
}

class KinokoLocalizationsDelegate extends LocalizationsDelegate<KinokoLocalizations> {
  static const List<String> supports = const <String>["zh", "en"];

  const KinokoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return true;
  }

  @override
  Future<KinokoLocalizations> load(Locale locale) {
    return SynchronousFuture<KinokoLocalizations>(KinokoLocalizations(zhHans.words, zhHans.words));
  }

  @override
  bool shouldReload(LocalizationsDelegate old) => false;
}

String Function(String) lc(BuildContext ctx) {
  KinokoLocalizations loc = Localizations.of<KinokoLocalizations>(ctx, KinokoLocalizations);
  return (String key)=>loc.get(key);
}

extension KinokoLocalizationsWidget on Widget {
  String kt(BuildContext context, String key) {
    return Localizations.of<KinokoLocalizations>(context, KinokoLocalizations).get(key);
  }
}

extension KinokoLocalizationsState on State {
  String kt(String key) {
    return Localizations.of<KinokoLocalizations>(this.context, KinokoLocalizations).get(key);
  }
}