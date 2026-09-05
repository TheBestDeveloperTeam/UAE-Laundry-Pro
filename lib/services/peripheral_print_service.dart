import 'package:laundrypro_uae/core/receipt_model.dart';
import 'package:laundrypro_uae/peripherals/core/printer/paper_size.dart';
import 'package:laundrypro_uae/peripherals/core/printer/pos_receipt_builder.dart';
import 'package:laundrypro_uae/peripherals/core/printer/pos_receipt_model.dart';
import 'package:laundrypro_uae/peripherals/core/printer/printer_manager.dart';

class PeripheralPrintResult {
  const PeripheralPrintResult({required this.success, this.error});

  final bool success;
  final String? error;
}

class PeripheralPrintService {
  PeripheralPrintService({
    required PrinterManager printerManager,
    required String? selectedPrinter,
    this.arabicCodePage = 32,
    this.reverseArabicRtl = true,
    this.paper = PaperSize.thermal80mm,
    this.copies = 1,
  })  : _printerManager = printerManager,
        _selectedPrinter = selectedPrinter;

  final PrinterManager _printerManager;
  final String? _selectedPrinter;
  final int arabicCodePage;
  final bool reverseArabicRtl;
  final PaperSize paper;
  final int copies;

  static PosShopProfile shopProfileFrom({
    String? businessName,
    String? businessNameAr,
  }) {
    final name = businessName?.trim();
    return PosShopProfile(
      shopNameEn: name?.isNotEmpty == true ? name! : 'LaundryPro UAE',
      shopNameAr: businessNameAr?.trim().isNotEmpty == true
          ? businessNameAr!.trim()
          : (name?.isNotEmpty == true ? name! : 'لاندري برو الإمارات'),
    );
  }

  static List<PosReceiptLineItem> lineItemsFromReceipt(ReceiptModel receipt) {
    return receipt.lines
        .map(
          (line) => PosReceiptLineItem(
            nameEn: line.description,
            nameAr: line.description,
            qty: line.quantity.round().clamp(1, 9999),
            unitPrice: line.rate,
          ),
        )
        .toList(growable: false);
  }

  static List<PosReceiptLineItem> lineItemsFromOrder(Map<String, dynamic> order) {
    return ReceiptModel.fromOrder(order).lines
        .map(
          (line) => PosReceiptLineItem(
            nameEn: line.description,
            nameAr: line.description,
            qty: line.quantity.round().clamp(1, 9999),
            unitPrice: line.rate,
          ),
        )
        .toList(growable: false);
  }

  static PosReceiptBuilder builderFromReceipt(
    ReceiptModel receipt, {
    String? businessName,
    String? businessNameAr,
    String? cashier,
    PaperSize paper = PaperSize.thermal80mm,
  }) {
    return PosReceiptBuilder(
      shop: shopProfileFrom(
        businessName: businessName,
        businessNameAr: businessNameAr,
      ),
      items: lineItemsFromReceipt(receipt),
      paper: paper,
      receiptNo: receipt.orderNo,
      cashier: cashier,
    );
  }

  static PosReceiptBuilder builderFromOrder(
    Map<String, dynamic> order, {
    String? businessName,
    String? businessNameAr,
    String? cashier,
    PaperSize paper = PaperSize.thermal80mm,
  }) {
    final receipt = ReceiptModel.fromOrder(order);
    return PosReceiptBuilder(
      shop: shopProfileFrom(
        businessName: businessName,
        businessNameAr: businessNameAr,
      ),
      items: lineItemsFromOrder(order),
      paper: paper,
      receiptNo: receipt.orderNo,
      cashier: cashier,
    );
  }

  Future<PeripheralPrintResult> printReceipt(
    ReceiptModel receipt, {
    String? businessName,
    String? businessNameAr,
    String? cashier,
  }) async {
    return _printBuilder(
      builderFromReceipt(
        receipt,
        businessName: businessName,
        businessNameAr: businessNameAr,
        cashier: cashier,
        paper: paper,
      ),
    );
  }

  Future<PeripheralPrintResult> printOrder(
    Map<String, dynamic> order, {
    String? businessName,
    String? businessNameAr,
    String? cashier,
  }) async {
    return _printBuilder(
      builderFromOrder(
        order,
        businessName: businessName,
        businessNameAr: businessNameAr,
        cashier: cashier,
        paper: paper,
      ),
    );
  }

  Future<PeripheralPrintResult> openCashDrawer() async {
    final printer = _selectedPrinter?.trim();
    if (printer == null || printer.isEmpty) {
      return const PeripheralPrintResult(
        success: false,
        error: 'No printer selected',
      );
    }
    try {
      await _printerManager.printToInstalledPrinter(
        printerName: printer,
        payload: _printerManager.cashDrawerPulse(),
      );
      return const PeripheralPrintResult(success: true);
    } catch (error) {
      return PeripheralPrintResult(success: false, error: error.toString());
    }
  }

  Future<PeripheralPrintResult> _printBuilder(PosReceiptBuilder builder) async {
    final printer = _selectedPrinter?.trim();
    if (printer == null || printer.isEmpty) {
      return const PeripheralPrintResult(
        success: false,
        error: 'No printer selected',
      );
    }

    try {
      final payload = _printerManager.buildPosShopReceipt(
        shop: builder.shop,
        items: builder.items,
        paper: paper,
        receiptNo: builder.receiptNo,
        cashier: builder.cashier,
        arabicCodePage: arabicCodePage,
        reverseArabicRtl: reverseArabicRtl,
        copies: copies,
      );
      await _printerManager.printToInstalledPrinter(
        printerName: printer,
        payload: payload,
      );
      return const PeripheralPrintResult(success: true);
    } catch (error) {
      return PeripheralPrintResult(success: false, error: error.toString());
    }
  }
}
