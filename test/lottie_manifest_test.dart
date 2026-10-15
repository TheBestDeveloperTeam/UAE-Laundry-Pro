import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/core/lottie/lottie_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('manifest has 5000+ bindings and valid master paths', () async {
    final raw = await rootBundle.loadString(LottieCatalog.manifestAsset);
    LottieCatalog.instance.loadFromJsonString(raw);

    expect(LottieCatalog.instance.bindingCount(), greaterThanOrEqualTo(5000));

    final binding = LottieCatalog.instance.resolve('splash.bg.light');
    expect(binding, isNotNull);
    expect(binding!.assetPath, startsWith('assets/animations/masters/'));
    expect(binding.assetPath, endsWith('.json'));
  });
}
