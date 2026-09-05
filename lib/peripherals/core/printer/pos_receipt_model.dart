/// Line item on a POS thermal receipt.
class PosReceiptLineItem {
  const PosReceiptLineItem({
    required this.nameEn,
    required this.nameAr,
    required this.qty,
    required this.unitPrice,
  });

  final String nameEn;
  final String nameAr;
  final int qty;
  final double unitPrice;

  double get lineTotal => qty * unitPrice;
}

/// Shop / business profile printed in the receipt header.
class PosShopProfile {
  const PosShopProfile({
    this.shopNameEn = 'SHOP NAME',
    this.shopNameAr = 'اسم المتجر',
    this.addressEn = '123 Main Street, Business Bay, Dubai',
    this.addressAr = '١٢٣ الشارع الرئيسي، الخليج التجاري، دبي',
    this.phoneEn = 'Tel: +971 4 123 4567',
    this.phoneAr = 'هاتف: +971 4 123 4567',
    this.emailEn = 'info@shopname.com',
    this.emailAr = 'info@shopname.com',
    this.vatPercent = 5.0,
    this.discountPercent = 2.0,
    this.verifyBaseUrl = 'https://receipt.verify',
    this.thankYouEn = 'Thank you, visit again...',
    this.thankYouAr = 'شكراً لزيارتكم، نراكم قريباً...',
  });

  final String shopNameEn;
  final String shopNameAr;
  final String addressEn;
  final String addressAr;
  final String phoneEn;
  final String phoneAr;
  final String emailEn;
  final String emailAr;
  final double vatPercent;
  final double discountPercent;

  /// Base URL embedded in QR codes for receipt verification.
  final String verifyBaseUrl;
  final String thankYouEn;
  final String thankYouAr;
}

/// Parsed view of a receipt line for UI preview (no ESC/POS bytes).
class ReceiptPreviewLine {
  const ReceiptPreviewLine({
    required this.text,
    this.textAr,
    this.align = ReceiptTextAlign.left,
    this.bold = false,
    this.big = false,
    this.isRule = false,
    this.isBarcode = false,
    this.isQr = false,
    this.isCode128 = false,
    this.barcodeLabel,
    this.rightText,
  });

  final String text;
  final String? textAr;
  final ReceiptTextAlign align;
  final bool bold;
  final bool big;
  final bool isRule;
  final bool isBarcode;
  final bool isQr;
  final bool isCode128;
  final String? barcodeLabel;

  /// Right column for summary rows (Subtotal, VAT, etc.).
  final String? rightText;
}

enum ReceiptTextAlign { left, center, right }
