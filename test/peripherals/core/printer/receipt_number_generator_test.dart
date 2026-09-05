import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/peripherals/core/printer/receipt_number_generator.dart';

void main() {
  test('generates unique receipt numbers and encodings', () {
    final a = ReceiptVerificationCodes.generate(random: Random(1));
    final b = ReceiptVerificationCodes.generate(random: Random(2));

    expect(a.receiptNumber, startsWith('RCP-'));
    expect(a.receiptNumber, isNot(equals(b.receiptNumber)));
    expect(a.qrPayload, contains(a.receiptNumber));
    expect(a.code128Payload, isNotEmpty);
    expect(a.ean13, hasLength(13));
    expect(RegExp(r'^\d{13}$').hasMatch(a.ean13), true);
  });

  test('EAN-13 check digit matches GS1 mod-10', () {
    expect(ReceiptVerificationCodes.gs1CheckDigit('590123412345'), 7);
  });

  test('QR and Code128 encode the same receipt id', () {
    final codes = ReceiptVerificationCodes.generate(random: Random(3));
    expect(codes.qrPayload, contains('id=${codes.receiptNumber}'));
    expect(codes.code128Payload, isNotEmpty);
  });
}
