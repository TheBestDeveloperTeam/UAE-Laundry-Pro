import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

class AndroidCoreService {
  bool get isAndroid => Platform.isAndroid;

  Future<void> initializeWakeLocks() async {
    if (!isAndroid) return;
    // Deep dive Android WakeLocks for continuous peripheral scanning
  }

  Future<void> requestPermissions() async {
    if (!isAndroid) return;
    // Bluetooth, Location, Camera, USB Host permissions
  }
}

final androidCoreProvider = Provider<AndroidCoreService>((ref) {
  return AndroidCoreService();
});
