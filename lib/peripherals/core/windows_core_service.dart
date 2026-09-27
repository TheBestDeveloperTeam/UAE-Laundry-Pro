import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WindowsCoreService {
  static const MethodChannel _channel = MethodChannel('com.magnificentsolution.laundrypro/windows_core');

  bool get isWindows => Platform.isWindows;

  /// Deep dive into Windows Registry to configure specific peripheral COM ports and background spoolers
  Future<void> initializeRegistryKeys() async {
    if (!isWindows) return;
    try {
      // Dart FFI or MethodChannel to native Windows C++ code to set up offline services
      await _channel.invokeMethod('initializeRegistry', {
        'comPortDefaults': 'COM1,COM2',
        'enableSpoolerOverride': true,
      });
      print("Windows Registry successfully initialized for peripherals.");
    } on PlatformException catch (e) {
      print("Failed to initialize Windows registry: ${e.message}");
    }
  }

  /// Deep dive into registering an offline Windows Background Service for the Sync Engine
  Future<void> registerBackgroundServices() async {
    if (!isWindows) return;
    try {
      await _channel.invokeMethod('registerBackgroundService', {
        'serviceName': 'LaundryProSyncEngine',
        'startType': 'auto',
      });
      print("Windows Background Sync Service Registered.");
    } on PlatformException catch (e) {
      print("Failed to register Windows service: ${e.message}");
    }
  }
}

final windowsCoreProvider = Provider<WindowsCoreService>((ref) {
  return WindowsCoreService();
});
