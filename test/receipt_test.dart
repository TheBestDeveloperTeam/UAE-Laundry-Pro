import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/core/receipt_model.dart';
import 'package:laundrypro_uae/core/receipt_renderer.dart';

void main() {
  test('ReceiptModel parses order lines', () {
    final model = ReceiptModel.fromOrder({
      'order_no': 'SO-000001',
      'subtotal': '50.00',
      'grand_total': '50.00',
      'amount_paid': '20.00',
      'balance_due': '30.00',
      'lines': [
        {'description': 'Wash', 'quantity': 2, 'rate': 25, 'amount': 50},
      ],
    });
    expect(model.orderNo, 'SO-000001');
    expect(model.lines.length, 1);
    expect(model.grandTotal, 50);
    expect(model.balanceDue, 30);
  });

  test('thermal and PDF share same totals', () async {
    final model = ReceiptModel.fromOrder({
      'order_no': 'SO-000002',
      'subtotal': '100.00',
      'grand_total': '100.00',
      'amount_paid': '100.00',
      'balance_due': '0.00',
      'lines': [
        {'description': 'Iron', 'quantity': 1, 'rate': 100, 'amount': 100},
      ],
    });
    final thermal = ReceiptRenderer.toThermal(model);
    expect(thermal, contains('100'));
    expect(thermal, contains('SO-000002'));
    final pdf = await ReceiptRenderer.toA4Pdf(model);
    expect(pdf.isNotEmpty, true);
  });
}
