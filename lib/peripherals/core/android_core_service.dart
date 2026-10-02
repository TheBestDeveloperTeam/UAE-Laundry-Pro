import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundrypro_uae/core/logger.dart';

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
      AppLogger.info("Android Wakelock Acquired successfully.", tag: 'AndroidCoreService');
    } on PlatformException catch (e) {
      AppLogger.error("Failed to acquire wakelock: ${e.message}", tag: 'AndroidCoreService');
    }
  }

  /// Deep dive into explicitly requesting raw USB Host Mode permissions for OTG peripherals
  Future<void> requestUsbHostPermissions() async {
    if (!isAndroid) return;
    try {
      final bool granted = await _channel.invokeMethod('requestUsbPermissions');
      if (granted) {
        AppLogger.info("USB Host permissions granted. Ready for HID/Serial peripherals.", tag: 'AndroidCoreService');
      } else {
        AppLogger.warning("USB Host permissions denied by user or OS.", tag: 'AndroidCoreService');
      }
    } on PlatformException catch (e) {
      AppLogger.error("Failed to request USB permissions: ${e.message}", tag: 'AndroidCoreService');
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
