import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

enum ScannerMode { camera, usb_hid, bluetooth_spp }

class BarcodeScannerManager {
  ScannerMode _mode = ScannerMode.camera;

  void setMode(ScannerMode mode) {
    _mode = mode;
  }

  Future<String?> scan() async {
    if (_mode == ScannerMode.camera) {
      return await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.DEFAULT);
    } else if (_mode == ScannerMode.usb_hid) {
      // Deep dive Windows/Android USB HID event listening
      return "USB_HID_SCANNED_VALUE";
    } else {
      // Deep dive Bluetooth SPP scanning
      return "BLUETOOTH_SCANNED_VALUE";
    }
  }
}

final barcodeScannerProvider = Provider<BarcodeScannerManager>((ref) {
  return BarcodeScannerManager();
});
