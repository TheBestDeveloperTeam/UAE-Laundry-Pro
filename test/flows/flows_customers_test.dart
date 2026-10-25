import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/views/customers_screen.dart';
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

  testWidgets('Customer creation dialog opens and validates inputs', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final customerService = MockInteractiveCustomerService();
    await tester.pumpWidget(buildTestHarness(
      CustomersScreen(customerService: customerService),
      container: peripheralContainer,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Find "Add Customer" button and tap
    final addCustomerButton = find.text('Add Customer');
    expect(addCustomerButton, findsOneWidget);
    await tester.tap(addCustomerButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Dialog should be open with form fields
    expect(find.text('Register New Customer'), findsOneWidget);
    expect(find.text('Full Customer Name *'), findsOneWidget);
    expect(find.text('Phone Number (Mobile) *'), findsOneWidget);

    // Verify fields accept input
    final nameField = find.widgetWithText(TextField, 'Full Customer Name *');
    await tester.enterText(nameField, 'Khalid Al Marzouqi');
    await tester.pump();
    expect(find.text('Khalid Al Marzouqi'), findsOneWidget);

    final phoneField = find.widgetWithText(TextField, 'Phone Number (Mobile) *');
    await tester.enterText(phoneField, '0509988776');
    await tester.pump();
    expect(find.text('0509988776'), findsOneWidget);

    // Cancel dialog
    final cancelButton = find.text('Cancel');
    expect(cancelButton, findsOneWidget);
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(find.text('Register New Customer'), findsNothing);
  });
}
