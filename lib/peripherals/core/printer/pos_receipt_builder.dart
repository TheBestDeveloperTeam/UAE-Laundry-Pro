import 'package:laundrypro_uae/peripherals/core/printer/paper_size.dart';
import 'package:laundrypro_uae/peripherals/core/printer/pos_receipt_model.dart';
import 'package:laundrypro_uae/peripherals/core/printer/receipt_layout.dart';
import 'package:laundrypro_uae/peripherals/core/printer/receipt_number_generator.dart';

/// Builds markup for restaurant / garment POS thermal receipts.
///
/// Layout: merchant names left-aligned, prices right-aligned, section titles
/// centered, item table in fixed columns.
class PosReceiptBuilder {
  PosReceiptBuilder._({
    required this.shop,
    required this.items,
    required this.paper,
    required this.receiptNo,
    required this.cashier,
    required this.verificationCodes,
  });

  final PosShopProfile shop;
  final List<PosReceiptLineItem> items;
  final PaperSize paper;
  final String? receiptNo;
  final String? cashier;
  final ReceiptVerificationCodes verificationCodes;

  factory PosReceiptBuilder({
    PosShopProfile shop = const PosShopProfile(),
    List<PosReceiptLineItem> items = const [],
    PaperSize paper = PaperSize.thermal80mm,
    String? receiptNo,
    String? cashier,
    ReceiptVerificationCodes? verificationCodes,
  }) {
    final codes = verificationCodes ??
        ReceiptVerificationCodes.generate(verifyBaseUrl: shop.verifyBaseUrl);
    return PosReceiptBuilder._(
      shop: shop,
      items: items,
      paper: paper,
      receiptNo: receiptNo ?? codes.receiptNumber,
      cashier: cashier,
      verificationCodes: codes,
    );
  }

  /// Demo / preview sample with a fresh receipt number.
  factory PosReceiptBuilder.sample({PaperSize paper = PaperSize.thermal80mm}) {
    return PosReceiptBuilder(
      paper: paper,
      cashier: 'Admin',
      items: const [
        PosReceiptLineItem(
          nameEn: 'Arabic Coffee',
          nameAr: 'قهوة عربية',
          qty: 2,
          unitPrice: 12.5,
        ),
        PosReceiptLineItem(
          nameEn: 'Chicken Shawarma',
          nameAr: 'شاورما دجاج',
          qty: 1,
          unitPrice: 28.0,
        ),
        PosReceiptLineItem(
          nameEn: 'Cotton T-Shirt (L)',
          nameAr: 'تيشيرت قطن (L)',
          qty: 3,
          unitPrice: 45.0,
        ),
      ],
    );
  }

  /// Pre-loaded aligned template (same layout as sample; unique receipt per build).
  factory PosReceiptBuilder.preloadedTemplate({
    PaperSize paper = PaperSize.thermal80mm,
  }) {
    return PosReceiptBuilder.sample(paper: paper);
  }

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get discountAmount => subtotal * (shop.discountPercent / 100);

  double get afterDiscount => subtotal - discountAmount;

  double get vatAmount => afterDiscount * (shop.vatPercent / 100);

  double get grandTotal => afterDiscount + vatAmount;

  String _money(double value) => value.toStringAsFixed(2);

  int get _cols => paper.columns;

  /// Markup lines consumed by [RichLineFormatter] / [EscPosGenerator].
  List<String> buildMarkupLines() {
    final lines = <String>[];
    final codes = verificationCodes;

    lines.add('[L][BIG][B]${shop.shopNameEn}[/B][/BIG][/L]');
    lines.add('[L][BIG]${shop.shopNameAr}[/BIG][/L]');
    lines.add('[HR]');

    lines.add('[L][BI]${shop.addressEn}|${shop.addressAr}[/BI][/L]');
    lines.add('[L][BI]${shop.phoneEn}|${shop.phoneAr}[/BI][/L]');
    lines.add('[L][BI]${shop.emailEn}|${shop.emailAr}[/BI][/L]');

    if (receiptNo != null) {
      lines.add('[L][BI]Receipt: $receiptNo|فاتورة: $receiptNo[/BI][/L]');
    }
    if (cashier != null) {
      lines.add('[L][BI]Cashier: $cashier|كاشير: $cashier[/BI][/L]');
    }
    lines.add(
      '[L][BI]${DateTime.now().toString().substring(0, 19)}|${DateTime.now().toString().substring(0, 19)}[/BI][/L]',
    );
    lines.add('[HR]');

    lines.add('[C][B]PARTICULARS[/B][/C]');
    lines.add('[C]التفاصيل[/C]');
    lines.add('[HR]');
    lines.add(
      '[R3]${ReceiptLayout.clip('Item', _cols ~/ 3)}|Qty|Total[/R3]',
    );
    lines.add('[HR]');

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (i.isOdd) {
        lines.add('[C]································[/C]');
      }
      lines.add('[L][BI]${item.nameEn}|${item.nameAr}[/BI][/L]');
      lines.add(
        '[R3]|${item.qty}|${_money(item.lineTotal)}[/R3]',
      );
    }

    lines.add('[HR]');
    lines.add('[C][B]SUMMARY[/B][/C]');
    lines.add('[C]الملخص[/C]');
    lines.add('[HR]');
    lines.add(
      '[LR]Subtotal|${_money(subtotal)}[/LR]',
    );
    lines.add(
      '[LR]Discount (${shop.discountPercent.toStringAsFixed(0)}%)|${_money(discountAmount)}[/LR]',
    );
    lines.add(
      '[LR]VAT (${shop.vatPercent.toStringAsFixed(0)}%)|${_money(vatAmount)}[/LR]',
    );
    lines.add('[HR]');
    lines.add('[C][B][BIG]GRAND TOTAL[/BIG][/B][/C]');
    lines.add('[R][BIG][B]${_money(grandTotal)}[/BIG][/B][/R]');
    lines.add('[C][B][BIG]الإجمالي[/BIG][/B][/C]');
    lines.add('[R][BIG][B]${_money(grandTotal)}[/BIG][/B][/R]');
    lines.add('[HR]');

    lines.add('[C]Scan to verify[/C]');
    lines.add('[C][EAN13]${codes.ean13}[/EAN13]');
    lines.add('[C][BC]${codes.code128Payload}[/BC]');
    lines.add('[C][QR]${codes.qrPayload}[/QR]');
    lines.add('[C]$receiptNo[/C]');
    lines.add('[HR]');

    lines.add('[C][BI]${shop.thankYouEn}|${shop.thankYouAr}[/BI][/C]');
    lines.add('[FEED:3]');

    return lines;
  }

  /// Structured lines for the visual receipt preview widget.
  List<ReceiptPreviewLine> buildPreviewLines() {
    final codes = verificationCodes;
    final preview = <ReceiptPreviewLine>[
      ReceiptPreviewLine(
        text: shop.shopNameEn,
        textAr: shop.shopNameAr,
        align: ReceiptTextAlign.left,
        bold: true,
        big: true,
      ),
      const ReceiptPreviewLine(text: '', isRule: true),
      ReceiptPreviewLine(
        text: shop.addressEn,
        textAr: shop.addressAr,
        align: ReceiptTextAlign.left,
      ),
      ReceiptPreviewLine(
        text: shop.phoneEn,
        textAr: shop.phoneAr,
        align: ReceiptTextAlign.left,
      ),
      ReceiptPreviewLine(
        text: shop.emailEn,
        textAr: shop.emailAr,
        align: ReceiptTextAlign.left,
      ),
    ];

    if (receiptNo != null) {
      preview.add(
        ReceiptPreviewLine(
          text: 'Receipt: $receiptNo',
          textAr: 'فاتورة: $receiptNo',
          align: ReceiptTextAlign.left,
        ),
      );
    }
    if (cashier != null) {
      preview.add(
        ReceiptPreviewLine(
          text: 'Cashier: $cashier',
          textAr: 'كاشير: $cashier',
          align: ReceiptTextAlign.left,
        ),
      );
    }

    preview.addAll([
      const ReceiptPreviewLine(text: '', isRule: true),
      const ReceiptPreviewLine(
        text: 'PARTICULARS',
        textAr: 'التفاصيل',
        align: ReceiptTextAlign.center,
        bold: true,
      ),
      const ReceiptPreviewLine(text: '', isRule: true),
      ReceiptPreviewLine(
        text: ReceiptLayout.itemRow(
          name: 'Item',
          qty: 'Qty',
          amount: 'Total',
          columns: _cols,
        ),
        align: ReceiptTextAlign.left,
        bold: true,
      ),
      const ReceiptPreviewLine(text: '', isRule: true),
    ]);

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      preview.add(
        ReceiptPreviewLine(
          text: item.nameEn,
          textAr: item.nameAr,
          align: ReceiptTextAlign.left,
          bold: i.isEven,
        ),
      );
      preview.add(
        ReceiptPreviewLine(
          text: ReceiptLayout.itemRow(
            name: '',
            qty: '${item.qty}',
            amount: _money(item.lineTotal),
            columns: _cols,
          ),
          align: ReceiptTextAlign.right,
        ),
      );
    }

    preview.addAll([
      const ReceiptPreviewLine(text: '', isRule: true),
      const ReceiptPreviewLine(
        text: 'SUMMARY',
        textAr: 'الملخص',
        align: ReceiptTextAlign.center,
        bold: true,
      ),
      const ReceiptPreviewLine(text: '', isRule: true),
      ReceiptPreviewLine(
        text: 'Subtotal',
        rightText: _money(subtotal),
        align: ReceiptTextAlign.left,
      ),
      ReceiptPreviewLine(
        text: 'Discount (${shop.discountPercent.toStringAsFixed(0)}%)',
        rightText: _money(discountAmount),
        align: ReceiptTextAlign.left,
      ),
      ReceiptPreviewLine(
        text: 'VAT (${shop.vatPercent.toStringAsFixed(0)}%)',
        rightText: _money(vatAmount),
        align: ReceiptTextAlign.left,
      ),
      const ReceiptPreviewLine(text: '', isRule: true),
      const ReceiptPreviewLine(
        text: 'GRAND TOTAL',
        align: ReceiptTextAlign.center,
        bold: true,
        big: true,
      ),
      ReceiptPreviewLine(
        text: '',
        rightText: _money(grandTotal),
        align: ReceiptTextAlign.right,
        bold: true,
        big: true,
      ),
      const ReceiptPreviewLine(text: '', isRule: true),
      const ReceiptPreviewLine(
        text: 'Scan to verify',
        align: ReceiptTextAlign.center,
      ),
      ReceiptPreviewLine(
        text: 'EAN-13: ${codes.ean13}',
        align: ReceiptTextAlign.center,
        isBarcode: true,
        barcodeLabel: codes.ean13,
      ),
      ReceiptPreviewLine(
        text: 'Code128: ${codes.code128Payload}',
        align: ReceiptTextAlign.center,
        isCode128: true,
        barcodeLabel: codes.code128Payload,
      ),
      ReceiptPreviewLine(
        text: 'QR: ${codes.qrPayload}',
        align: ReceiptTextAlign.center,
        isQr: true,
        barcodeLabel: codes.qrPayload,
      ),
      ReceiptPreviewLine(
        text: receiptNo ?? '',
        align: ReceiptTextAlign.center,
      ),
      const ReceiptPreviewLine(text: '', isRule: true),
      ReceiptPreviewLine(
        text: shop.thankYouEn,
        textAr: shop.thankYouAr,
        align: ReceiptTextAlign.center,
      ),
    ]);

    return preview;
  }
}
