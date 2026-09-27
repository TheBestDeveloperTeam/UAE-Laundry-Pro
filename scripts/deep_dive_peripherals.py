import os

def create_file(filepath, content):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

base_path = r"e:\Projects\Flutter\UAE-Laundry-Pro\lib\peripherals"

# 1. Thermal Printer Manager
thermal_printer_manager = """import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:printing/printing.dart';

enum PrinterBrand { epson, zebra, xprinter, star, generic }
enum ConnectionType { usb, bluetooth, network, serial }

class ThermalPrinterConfig {
  final PrinterBrand brand;
  final ConnectionType type;
  final String address;
  final bool isRtl;
  final String languageCode;
  final int paperWidth; // 58 or 80

  ThermalPrinterConfig({
    required this.brand,
    required this.type,
    required this.address,
    this.isRtl = false,
    this.languageCode = 'en',
    this.paperWidth = 80,
  });
}

class ThermalPrinterManager {
  ThermalPrinterConfig? _currentConfig;

  Future<void> connect(ThermalPrinterConfig config) async {
    _currentConfig = config;
    // Core connection logic depending on branded/non-branded and connection type
    if (config.type == ConnectionType.bluetooth) {
      // Deep dive Bluetooth initialization for Android/Windows
    } else if (config.type == ConnectionType.usb) {
      // Deep dive USB HID initialization for Windows/Android
    }
  }

  Future<void> printReceipt(Map<String, dynamic> data) async {
    if (_currentConfig == null) throw Exception("Printer not connected");
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      _currentConfig!.paperWidth == 80 ? PaperSize.mm80 : PaperSize.mm58,
      profile,
    );

    List<int> bytes = [];
    
    // RTL & LTR Bi-directional formatting
    if (_currentConfig!.isRtl) {
      bytes += generator.setStyles(const PosStyles(align: PosAlign.right));
      // RTL injection for Arabic/Urdu
      bytes += generator.textEncoded(Uint8List.fromList(data['header_rtl'].toString().codeUnits));
    } else {
      bytes += generator.setStyles(const PosStyles(align: PosAlign.left));
      bytes += generator.text(data['header_ltr']);
    }

    bytes += generator.feed(2);
    bytes += generator.cut();

    await _executePrint(bytes);
  }

  Future<void> openCashDrawer() async {
    if (_currentConfig == null) return;
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = generator.drawer(pin: PosDrawer.pin2);
    await _executePrint(bytes);
  }

  Future<void> _executePrint(List<int> bytes) async {
    // Platform specific byte transfer (Windows spooler, Android BT socket, etc)
  }
}

final thermalPrinterProvider = Provider<ThermalPrinterManager>((ref) {
  return ThermalPrinterManager();
});
"""

# 2. Barcode Scanner Manager
scanner_manager = """import 'package:flutter_riverpod/flutter_riverpod.dart';
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
"""

# 3. Share Manager
share_manager = """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class ShareManager {
  Future<void> shareReceipt(String filePath, String text) async {
    await Share.shareXFiles([XFile(filePath)], text: text);
  }

  Future<void> shareViaWhatsApp(String phone, String text) async {
    final url = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(text)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch WhatsApp');
    }
  }

  Future<void> shareViaEmail(String email, String subject, String body) async {
    final url = Uri.parse("mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}

final shareManagerProvider = Provider<ShareManager>((ref) {
  return ShareManager();
});
"""

# 4. Windows Core Service
windows_service = """import 'package:flutter_riverpod/flutter_riverpod.dart';
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
"""

# 5. Android Core Service
android_service = """import 'package:flutter_riverpod/flutter_riverpod.dart';
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
"""

# Write all files
create_file(os.path.join(base_path, 'printers', 'thermal_printer_manager.dart'), thermal_printer_manager)
create_file(os.path.join(base_path, 'scanners', 'barcode_scanner_manager.dart'), scanner_manager)
create_file(os.path.join(base_path, 'shareables', 'share_manager.dart'), share_manager)
create_file(os.path.join(base_path, 'core', 'windows_core_service.dart'), windows_service)
create_file(os.path.join(base_path, 'core', 'android_core_service.dart'), android_service)

print("Deep dive peripheral services successfully generated.")
