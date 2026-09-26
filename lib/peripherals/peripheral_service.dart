import 'dart:async';

abstract class PrinterDriver {
  Future<bool> connect();
  Future<void> printReceipt(Map<String, dynamic> data);
  Future<void> openCashDrawer();
  Future<void> disconnect();
}

abstract class ScannerDriver {
  Stream<String> get onBarcodeScanned;
  Future<void> startListening();
  Future<void> stopListening();
}

class PeripheralService {
  PrinterDriver? _activePrinter;
  ScannerDriver? _activeScanner;

  // Singleton setup
  static final PeripheralService _instance = PeripheralService._internal();
  factory PeripheralService() => _instance;
  PeripheralService._internal();

  Future<void> initializePrinters(PrinterDriver driver) async {
    _activePrinter = driver;
    await _activePrinter?.connect();
  }

  Future<void> initializeScanner(ScannerDriver driver) async {
    _activeScanner = driver;
    await _activeScanner?.startListening();
  }

  Future<void> printDocument(Map<String, dynamic> payload) async {
    if (_activePrinter == null) {
      throw Exception('No active printer configured');
    }
    await _activePrinter!.printReceipt(payload);
  }

  Future<void> popCashDrawer() async {
    if (_activePrinter == null) {
      throw Exception('No active printer configured to pulse cash drawer');
    }
    await _activePrinter!.openCashDrawer();
  }

  Stream<String>? get barcodeStream => _activeScanner?.onBarcodeScanned;
}
