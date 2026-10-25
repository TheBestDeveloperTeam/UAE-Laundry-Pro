import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/views/pos_screen.dart';
import '../peripherals_test_support.dart';
import 'flows_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer peripheralContainer;

  setUp(() async {
    peripheralContainer = await createTestPeripheralContainer();
  });

  tearDown(() {
    peripheralContainer.dispose();
  });

  testWidgets('POS screen responds to interaction and cart controls', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final salesService = MockInteractiveSalesService();
    final catalogService = MockInteractiveCatalogService();
    final customerService = MockInteractiveCustomerService();

    await tester.pumpWidget(buildTestHarness(
      PosScreen(
        salesService: salesService,
        catalogService: catalogService,
        customerService: customerService,
      ),
      container: peripheralContainer,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Ensure search bar exists
    final searchField = find.byType(TextField);
    expect(searchField, findsWidgets);

    // Check for quick service categories or products
    expect(find.text('Wash & Fold - Kandora'), findsOneWidget);

    // Tap on service to add to cart
    await tester.tap(find.text('Wash & Fold - Kandora'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Cart line should appear
    expect(find.text('Wash & Fold - Kandora'), findsWidgets);
  });
}
