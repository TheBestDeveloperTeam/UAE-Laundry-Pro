import 'dart:typed_data';
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
