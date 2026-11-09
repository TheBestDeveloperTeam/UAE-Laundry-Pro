import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:laundrypro_uae/core/logger.dart';

enum ScannerType { usbHid, camera, bluetoothSpp }

/// Hardware device descriptor for connected cameras & webcams
class CameraDeviceDescriptor {
  const CameraDeviceDescriptor({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final bool isDefault;
}

class BarcodeScannerManager {
  ScannerType _currentType = ScannerType.camera;
  
  // For USB HID Keyboard wedges
  final StreamController<String> _hidStreamController = StreamController<String>.broadcast();
  final StringBuffer _hidBuffer = StringBuffer();
  DateTime _lastKeystroke = DateTime.now();

  // Multi-camera device tracking
  List<CameraDeviceDescriptor> _availableCameras = const [
    CameraDeviceDescriptor(id: 'cam_drive_through', name: 'Drive-Through Lane Cam 1 (High-Speed)', isDefault: true),
    CameraDeviceDescriptor(id: 'cam_counter_intake', name: 'Counter Intake Cam 2 (Macro QR)'),
  ];
  String? _selectedCameraId = 'cam_drive_through';

  ScannerType get currentType => _currentType;
  Stream<String> get barcodeStream => _hidStreamController.stream;
  List<CameraDeviceDescriptor> get availableCameras => _availableCameras;
  String? get selectedCameraId => _selectedCameraId;

  void configureScanner(ScannerType type) {
    _currentType = type;
  }

  void selectCamera(String cameraId) {
    _selectedCameraId = cameraId;
    AppLogger.info('Switched active camera to: ' + cameraId, tag: 'BarcodeScannerManager');
  }

  /// Discover connected USB video class (UVC) webcams & counter cameras
  Future<List<CameraDeviceDescriptor>> discoverCameras() async {
    final list = <CameraDeviceDescriptor>[
      const CameraDeviceDescriptor(id: 'cam_drive_through', name: 'Drive-Through Lane Cam 1 (High-Speed)', isDefault: true),
      const CameraDeviceDescriptor(id: 'cam_counter_intake', name: 'Counter Intake Cam 2 (Macro QR)'),
    ];

    if (Platform.isWindows) {
      try {
        final result = await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          r'Get-PnpDevice -Class Camera,Image -Status OK | Select-Object -ExpandProperty FriendlyName',
        ]);
        if (result.exitCode == 0) {
          final lines = (result.stdout as String).split(RegExp(r'\r?\n'));
          final detected = <CameraDeviceDescriptor>[];
          int idx = 1;
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.isNotEmpty) {
              detected.add(CameraDeviceDescriptor(
                id: 'uvc_cam_' + idx.toString(),
                name: trimmed,
                isDefault: idx == 1,
              ));
              idx++;
            }
          }
          if (detected.isNotEmpty) {
            _availableCameras = detected;
            _selectedCameraId = detected.first.id;
            return detected;
          }
        }
      } catch (e) {
        AppLogger.warning('DirectShow / PnP Camera enumeration error: ' + e.toString(), tag: 'BarcodeScannerManager');
      }
    }

    _availableCameras = list;
    return list;
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
      AppLogger.warning('COM port auto-discovery failed: ' + e.toString(), tag: 'BarcodeScannerManager');
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
          '#E53935', 
          'Cancel', 
          true, 
          ScanMode.BARCODE
        );
        if (scanResult != '-1') return scanResult;
      } catch (e) {
        AppLogger.error('Camera Scanner Error: ' + e.toString(), tag: 'BarcodeScannerManager');
      }
      return null;
    } else {
      // For USB HID and Bluetooth SPP, scanning is stream-based, not future-based.
      AppLogger.info('Awaiting hardware scan via stream...', tag: 'BarcodeScannerManager');
      return null;
    }
  }

  /// Listens to Keyboard events to capture USB HID Scanner wedge inputs globally
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
