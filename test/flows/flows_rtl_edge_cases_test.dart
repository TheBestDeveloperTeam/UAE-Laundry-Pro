import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/views/customers_screen.dart';
import 'package:laundrypro_uae/views/expenses_screen.dart';
import 'package:laundrypro_uae/views/pos_screen.dart';
import '../support/peripherals_test_support.dart';
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

  group('Arabic / RTL Edge Case Audits', () {
    testWidgets('Customers screen renders in RTL (Arabic) with no overflow', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final customerService = MockInteractiveCustomerService();
      await tester.pumpWidget(buildTestHarness(
        CustomersScreen(customerService: customerService),
        container: peripheralContainer,
        isRtl: true,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    testWidgets('POS screen renders in RTL (Arabic) with no overflow', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
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
        isRtl: true,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Expenses screen renders in RTL (Arabic) with no overflow', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final expenseService = MockInteractiveExpenseService();
      await tester.pumpWidget(buildTestHarness(
        ExpensesScreen(expenseService: expenseService),
        container: peripheralContainer,
        isRtl: true,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Compact mobile display dimensions (360x640) render POS without fatal overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
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

      final err = tester.takeException();
      if (err != null) {
        debugPrint('COMPACT OVERFLOW ERROR: $err');
      }
      expect(err, isNull);
    });
  });
}
