import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/router/app_router.dart';
import 'package:laundrypro_uae/services/auth_service.dart';

void main() {
  test('Router initial location is splash', () {
    final auth = AuthProvider(AuthService());
    final router = AppRouter.create(auth);
    expect(router.routeInformationProvider.value.uri.path, '/splash');
  });
}