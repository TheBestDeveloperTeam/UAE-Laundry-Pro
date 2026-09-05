import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider({String initialLocale = 'en'}) : _locale = initialLocale;

  String _locale;

  String get locale => _locale;

  bool get isRtl => _locale == 'ar';

  TextDirection get textDirection => isRtl ? TextDirection.rtl : TextDirection.ltr;

  void setLocale(String locale) {
    if (_locale == locale) {
      return;
    }
    _locale = locale;
    notifyListeners();
  }
}
