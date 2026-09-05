import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/peripherals/core/printer/paper_size.dart';
import 'package:laundrypro_uae/peripherals/core/printer/pos_receipt_model.dart';
import 'package:laundrypro_uae/peripherals/core/printer/pos_receipt_builder.dart';
import 'package:laundrypro_uae/peripherals/core/printer/rich_line_formatter.dart';

void main() {
  test('sample receipt uses aligned layout and unique codes', () {
    final builder = PosReceiptBuilder.sample();
    final lines = builder.buildMarkupLines();

    expect(lines.any((l) => l.contains('[L][BIG][B]SHOP NAME')), true);
    expect(lines.any((l) => l.contains('[LR]Subtotal|')), true);
    expect(lines.any((l) => l.contains('[R3]|')), true);
    expect(lines.any((l) => l.contains('[EAN13]')), true);
    expect(lines.any((l) => l.contains('[QR]')), true);
    expect(lines.any((l) => l.contains('[BC]')), true);
    expect(builder.grandTotal, greaterThan(0));

    final eanLine = lines.firstWhere((l) => l.contains('[EAN13]'));
    final eanDigits =
        RegExp(r'\[EAN13\](\d{13})').firstMatch(eanLine)!.group(1)!;
    expect(eanDigits, builder.verificationCodes.ean13);
  });

  test('preloaded template matches aligned markup', () {
    final lines = PosReceiptBuilder.preloadedTemplate().buildMarkupLines();
    expect(lines.any((l) => l.startsWith('[L][BI]Receipt:')), true);
    expect(lines.any((l) => l.contains('[C][B]PARTICULARS')), true);
  });

  test('preview lines stack english and arabic left in header', () {
    final preview = PosReceiptBuilder.sample().buildPreviewLines();
    final shop = preview.first;
    expect(shop.align, ReceiptTextAlign.left);
    expect(shop.textAr, isNotEmpty);
  });

  test('LR and R3 markup emit printable rows', () {
    final formatter = RichLineFormatter(paper: PaperSize.thermal80mm);
    final lr = formatter.formatLine('[LR]Subtotal|123.45[/LR]');
    final r3 = formatter.formatLine('[R3]Coffee|2|25.00[/R3]');
    expect(lr.contains(0x0A), true);
    expect(r3.contains(0x0A), true);
  });

  test('EAN13 markup emits GS k command', () {
    final formatter = RichLineFormatter(paper: PaperSize.thermal80mm);
    final bytes = formatter.formatLine('[EAN13]5901234123457[/EAN13]');
    var found = false;
    for (var i = 0; i < bytes.length - 2; i++) {
      if (bytes[i] == 0x1D && bytes[i + 1] == 0x6B) {
        found = true;
        break;
      }
    }
    expect(found, true);
  });

  test('receipt numbers are unique per builder instance', () {
    final a = PosReceiptBuilder.sample();
    final b = PosReceiptBuilder.sample();
    expect(a.receiptNo, isNot(equals(b.receiptNo)));
    expect(
      a.verificationCodes.qrPayload,
      isNot(equals(b.verificationCodes.qrPayload)),
    );
  });
}
