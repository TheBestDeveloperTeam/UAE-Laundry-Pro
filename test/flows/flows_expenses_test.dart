import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/views/expenses_screen.dart';
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

  testWidgets('Expenses creation dialog opens and interacts with form', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final expenseService = MockInteractiveExpenseService();
    await tester.pumpWidget(buildTestHarness(
      ExpensesScreen(expenseService: expenseService),
      container: peripheralContainer,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Floating action button for creating expense
    final addExpenseFab = find.byType(FloatingActionButton);
    expect(addExpenseFab, findsOneWidget);
    await tester.tap(addExpenseFab);
    await tester.pumpAndSettle();

    // Enter amount in the dialog
    final amountField = find.byType(TextField).first;
    await tester.enterText(amountField, '250.75');
    await tester.pump();
    expect(find.text('250.75'), findsOneWidget);

    // Close modal
    final cancelBtn = find.text('Close');
    expect(cancelBtn, findsOneWidget);
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();
  });
}
