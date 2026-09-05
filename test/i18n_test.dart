import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> en;
  late Map<String, dynamic> ar;

  setUpAll(() async {
    en = json.decode(await rootBundle.loadString('assets/lang/en.json')) as Map<String, dynamic>;
    ar = json.decode(await rootBundle.loadString('assets/lang/ar.json')) as Map<String, dynamic>;
  });

  void expectKeyParity(String key) {
    test('en/ar parity for $key', () {
      expect(en.containsKey(key), isTrue, reason: 'missing in en.json');
      expect(ar.containsKey(key), isTrue, reason: 'missing in ar.json');
    });
  }

  for (final key in [
    'app_name',
    'catalog',
    'settings',
    'business_profile',
    'dashboard',
    'customers',
    'vendors',
    'pos',
    'backup',
    'setup_wizard',
    'reports_sales',
    'pending_invoices',
  ]) {
    expectKeyParity(key);
  }
}
