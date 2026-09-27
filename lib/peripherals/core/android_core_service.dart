import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AndroidCoreService {
  static const MethodChannel _channel = MethodChannel('com.magnificentsolution.laundrypro/android_core');

  bool get isAndroid => Platform.isAndroid;

  /// Deep dive Android Wakelock initialization to prevent the tablet from sleeping
  /// during active RFID or barcode scanning sessions.
  Future<void> initializeWakeLocks() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod('acquireWakeLock', {
        'tag': 'LaundryPro:PeripheralScannerLock',
        'timeoutMs': 3600000 // 1 hour timeout
      });
      print("Android Wakelock Acquired successfully.");
    } on PlatformException catch (e) {
      print("Failed to acquire wakelock: ${e.message}");
    }
  }

  /// Deep dive into explicitly requesting raw USB Host Mode permissions for OTG peripherals
  Future<void> requestUsbHostPermissions() async {
    if (!isAndroid) return;
    try {
      final bool granted = await _channel.invokeMethod('requestUsbPermissions');
      if (granted) {
        print("USB Host permissions granted. Ready for HID/Serial peripherals.");
      } else {
        print("USB Host permissions denied by user or OS.");
      }
    } on PlatformException catch (e) {
      print("Failed to request USB permissions: ${e.message}");
    }
  }

  /// Release wakelocks when backgrounding the app
  Future<void> releaseWakeLocks() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod('releaseWakeLock');
    } catch (e) {
      // Ignore
    }
  }
}

final androidCoreProvider = Provider<AndroidCoreService>((ref) {
  return AndroidCoreService();
});
