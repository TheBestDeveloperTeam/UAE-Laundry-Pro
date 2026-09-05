import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalization {
  AppLocalization(this.locale, this._strings);

  final String locale;
  final Map<String, String> _strings;

  static Future<AppLocalization> load(String locale) async {
    final jsonString = await rootBundle.loadString('assets/lang/$locale.json');
    final Map<String, dynamic> decoded = json.decode(jsonString);
    final strings = decoded.map((key, value) => MapEntry(key, value.toString()));
    return AppLocalization(locale, strings);
  }

  String t(String key) => _strings[key] ?? key;

  bool get isRtl => locale == 'ar';

  TextDirection get textDirection => isRtl ? TextDirection.rtl : TextDirection.ltr;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalization> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalization> load(Locale locale) => AppLocalization.load(locale.languageCode);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalization> old) => false;
}
