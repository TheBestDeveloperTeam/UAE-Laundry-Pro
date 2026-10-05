import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:laundrypro_uae/core/logger.dart';

enum ScannerType { usbHid, camera, bluetoothSpp }

class BarcodeScannerManager {
  ScannerType _currentType = ScannerType.camera;
  
  // For USB HID Keyboard wedges
  final StreamController<String> _hidStreamController = StreamController<String>.broadcast();
  final StringBuffer _hidBuffer = StringBuffer();
  DateTime _lastKeystroke = DateTime.now();

  ScannerType get currentType => _currentType;
  Stream<String> get barcodeStream => _hidStreamController.stream;

  void configureScanner(ScannerType type) {
    _currentType = type;
  }

  /// Auto-detect available COM ports on Windows workstation (TSK-3.1)
  static Future<List<String>> detectAvailableComPorts() async {
    final ports = <String>[];
    if (identical(0, 0.0)) return ports; // Web check

    try {
      // Query Windows Registry or WMI via PowerShell for COM ports
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        r'[System.IO.Ports.SerialPort]::GetPortNames()',
      ]);
      if (result.exitCode == 0) {
        final lines = (result.stdout as String).split(RegExp(r'\r?\n'));
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('COM')) {
            ports.add(trimmed);
          }
        }
      }
    } catch (e) {
      AppLogger.warning('COM port auto-discovery failed: $e', tag: 'BarcodeScannerManager');
    }

    if (ports.isEmpty) {
      ports.addAll(['COM1', 'COM2', 'COM3', 'COM4']); // Standard fallback scan targets
    }
    return ports;
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
        AppLogger.error("Camera Scanner Error: $e", tag: 'BarcodeScannerManager');
      }
      return null;
    } else {
      // For USB HID and Bluetooth SPP, scanning is stream-based, not future-based.
      // This method acts as a trigger or placeholder for manual SPP connection attempts.
      AppLogger.info("Awaiting hardware scan via stream...", tag: 'BarcodeScannerManager');
      return null;
    }
  }

  /// Listens to Keyboard events to capture USB HID Scanner wedge inputs globally
  /// Must be injected into the root widget tree
  void handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
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
      } else if (keyLabel.length == 1) {
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
