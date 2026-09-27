import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

class WindowsCoreService {
  bool get isWindows => Platform.isWindows;

  Future<void> initializeRegistryKeys() async {
    if (!isWindows) return;
    // Deep dive Windows Registry adjustments for POS peripherals
  }

  Future<void> registerBackgroundServices() async {
    if (!isWindows) return;
    // Windows Service registration for offline queueing
  }
}

final windowsCoreProvider = Provider<WindowsCoreService>((ref) {
  return WindowsCoreService();
});
