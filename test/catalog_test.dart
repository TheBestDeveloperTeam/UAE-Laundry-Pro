import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog strings present in en and ar', () async {
    final en = json.decode(await rootBundle.loadString('assets/lang/en.json')) as Map<String, dynamic>;
    final ar = json.decode(await rootBundle.loadString('assets/lang/ar.json')) as Map<String, dynamic>;
    expect(en['catalog'], isNotNull);
    expect(ar['catalog'], isNotNull);
    expect(en['settings'], isNotNull);
    expect(ar['settings'], isNotNull);
  });
}
