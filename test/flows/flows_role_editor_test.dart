import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/views/role_editor_screen.dart';
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

  testWidgets('Role Editor RBAC permission toggling works without errors', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final apiClient = MockInteractiveApiClient();
    await tester.pumpWidget(buildTestHarness(
      RoleEditorScreen(apiClient: apiClient),
      container: peripheralContainer,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Check that add role icon exists
    final addIcon = find.byIcon(Icons.add);
    expect(addIcon, findsOneWidget);

    // Tap add role to open permission matrix dialog
    await tester.tap(addIcon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Expansion tiles and checkboxes should appear
    final checkBoxes = find.byType(Checkbox);
    expect(checkBoxes, findsWidgets);

    // Toggle first available checkbox
    await tester.tap(checkBoxes.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Close dialog
    final cancelBtn = find.text('Cancel');
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();
  });
}
