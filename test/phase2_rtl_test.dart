import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const phase2Keys = [
    'production',
    'delivery',
    'challans',
    'purchasing',
    'employees',
    'attendance',
    'leave',
    'payroll',
    'expenses',
    'reports',
    'notifications',
    'reports_sales',
    'reports_expenses',
    'reports_payroll',
    'reports_inventory',
    'reports_production',
  ];

  test('phase 2 navigation keys exist in en and ar', () async {
    final en = json.decode(await rootBundle.loadString('assets/lang/en.json')) as Map<String, dynamic>;
    final ar = json.decode(await rootBundle.loadString('assets/lang/ar.json')) as Map<String, dynamic>;

    for (final key in phase2Keys) {
      expect(en[key], isNotNull, reason: 'en missing $key');
      expect(ar[key], isNotNull, reason: 'ar missing $key');
      expect((ar[key] as String).isNotEmpty, isTrue, reason: 'ar empty for $key');
    }
  });
}
