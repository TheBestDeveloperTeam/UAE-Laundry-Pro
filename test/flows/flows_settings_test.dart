import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/views/settings_screen.dart';
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

  testWidgets('Settings screen tabs and theme/VAT settings render cleanly', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final settingsService = MockInteractiveSettingsService();
    final backupService = MockInteractiveBackupService();
    await tester.pumpWidget(buildTestHarness(
      SettingsScreen(
        settingsService: settingsService,
        backupService: backupService,
      ),
      container: peripheralContainer,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(Card), findsWidgets);
    expect(find.byType(TextField), findsWidgets);
  });
}
