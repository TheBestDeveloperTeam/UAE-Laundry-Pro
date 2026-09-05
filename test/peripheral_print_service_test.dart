import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/core/receipt_model.dart';
import 'package:laundrypro_uae/peripherals/core/printer/paper_size.dart';
import 'package:laundrypro_uae/services/peripheral_print_service.dart';

void main() {
  test('maps ReceiptModel to PosReceiptBuilder markup', () {
    final receipt = ReceiptModel(
      orderNo: 'ORD-1001',
      lines: [
        ReceiptLine(
          description: 'Wash & Fold',
          quantity: 2,
          rate: 15,
          amount: 30,
        ),
      ],
      subtotal: 30,
      grandTotal: 31.5,
      amountPaid: 31.5,
      balanceDue: 0,
    );

    final builder = PeripheralPrintService.builderFromReceipt(
      receipt,
      businessName: 'Test Laundry',
      cashier: 'Cashier 1',
      paper: PaperSize.thermal80mm,
    );

    final lines = builder.buildMarkupLines();
    expect(builder.receiptNo, 'ORD-1001');
    expect(lines.any((line) => line.contains('Test Laundry')), true);
    expect(lines.any((line) => line.contains('Wash & Fold')), true);
    expect(builder.grandTotal, greaterThan(0));
  });

  test('maps order map to line items', () {
    final order = {
      'order_no': 'ORD-2002',
      'subtotal': 20,
      'grand_total': 21,
      'amount_paid': 21,
      'balance_due': 0,
      'lines': [
        {
          'description': 'Dry Clean',
          'quantity': 1,
          'rate': 20,
          'amount': 20,
        },
      ],
    };

    final items = PeripheralPrintService.lineItemsFromOrder(order);
    expect(items, hasLength(1));
    expect(items.first.nameEn, 'Dry Clean');
    expect(items.first.qty, 1);
    expect(items.first.unitPrice, 20);
  });
}
