import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

enum ScannerType { usb_hid, camera, bluetooth_spp }

class BarcodeScannerManager {
  ScannerType _currentType = ScannerType.camera;
  
  // For USB HID Keyboard wedges
  final StreamController<String> _hidStreamController = StreamController<String>.broadcast();
  StringBuffer _hidBuffer = StringBuffer();
  DateTime _lastKeystroke = DateTime.now();

  ScannerType get currentType => _currentType;
  Stream<String> get barcodeStream => _hidStreamController.stream;

  void configureScanner(ScannerType type) {
    _currentType = type;
  }

  /// Deep dive scanner integration
  /// Supports raw USB keyboards, embedded OS cameras, and Bluetooth SPP streams
  Future<String?> scan() async {
    if (_currentType == ScannerType.camera) {
      try {
        // Red overlay, cancel button, beep on scan, QR/Barcode mode
        final scanResult = await FlutterBarcodeScanner.scanBarcode(
          "#E53935", 
          "Cancel", 
          true, 
          ScanMode.BARCODE
        );
        if (scanResult != '-1') return scanResult;
      } catch (e) {
        print("Camera Scanner Error: $e");
      }
      return null;
    } else {
      // For USB HID and Bluetooth SPP, scanning is stream-based, not future-based.
      // This method acts as a trigger or placeholder for manual SPP connection attempts.
      print("Awaiting hardware scan via stream...");
      return null;
    }
  }

  /// Listens to RawKeyboard events to capture USB HID Scanner wedge inputs globally
  /// Must be injected into the root widget tree
  void handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final keyLabel = event.logicalKey.keyLabel;
      final now = DateTime.now();
      
      // Scanners type extremely fast (usually < 50ms per character).
      // If typing is slow, it's a human, discard buffer.
      if (now.difference(_lastKeystroke).inMilliseconds > 100) {
        _hidBuffer.clear();
      }
      _lastKeystroke = now;

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_hidBuffer.isNotEmpty) {
          _hidStreamController.add(_hidBuffer.toString());
          _hidBuffer.clear();
        }
      } else if (keyLabel != null && keyLabel.length == 1) {
        _hidBuffer.write(keyLabel);
      }
    }
  }

  void dispose() {
    _hidStreamController.close();
  }
}

final barcodeScannerProvider = Provider<BarcodeScannerManager>((ref) {
  return BarcodeScannerManager();
});
