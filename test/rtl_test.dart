import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/providers/locale_provider.dart';

void main() {
  test('Arabic locale enables RTL', () {
    final provider = LocaleProvider();
    provider.setLocale('ar');
    expect(provider.textDirection, TextDirection.rtl);
    expect(provider.locale, 'ar');
  });

  test('English locale is LTR', () {
    final provider = LocaleProvider();
    provider.setLocale('en');
    expect(provider.textDirection, TextDirection.ltr);
  });
}
