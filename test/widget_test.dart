import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/providers/locale_provider.dart';
import 'package:laundrypro_uae/services/auth_service.dart';

void main() {
  test('AuthProvider starts unknown', () {
    final provider = AuthProvider(AuthService());
    expect(provider.status, AuthStatus.unknown);
  });

  test('LocaleProvider defaults to English LTR', () {
    final provider = LocaleProvider();
    expect(provider.locale, 'en');
    expect(provider.isRtl, isFalse);
  });

  test('LocaleProvider switches to Arabic RTL', () {
    final provider = LocaleProvider();
    provider.setLocale('ar');
    expect(provider.locale, 'ar');
    expect(provider.isRtl, isTrue);
  });
}
