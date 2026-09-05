import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/core/receipt_model.dart';
import 'package:laundrypro_uae/core/receipt_renderer.dart';
import 'package:laundrypro_uae/models/user_model.dart';

void main() {
  group('ReceiptModel', () {
    test('handles empty lines', () {
      final model = ReceiptModel.fromOrder({
        'order_no': 'SO-EMPTY',
        'subtotal': '0',
        'grand_total': '0',
        'amount_paid': '0',
        'balance_due': '0',
        'lines': [],
      });
      expect(model.lines, isEmpty);
      expect(model.grandTotal, 0);
    });

    test('parses multiple lines', () {
      final model = ReceiptModel.fromOrder({
        'order_no': 'SO-MULTI',
        'subtotal': '75',
        'grand_total': '75',
        'amount_paid': '75',
        'balance_due': '0',
        'lines': [
          {'description': 'Wash', 'quantity': 1, 'rate': 25, 'amount': 25},
          {'description': 'Iron', 'quantity': 2, 'rate': 25, 'amount': 50},
        ],
      });
      expect(model.lines.length, 2);
      expect(model.lines.last.description, 'Iron');
    });

    test('thermal includes all line descriptions', () {
      final model = ReceiptModel.fromOrder({
        'order_no': 'SO-THERM',
        'subtotal': '40',
        'grand_total': '40',
        'amount_paid': '40',
        'balance_due': '0',
        'lines': [
          {'description': 'Dry Clean', 'quantity': 1, 'rate': 40, 'amount': 40},
        ],
      });
      final text = ReceiptRenderer.toThermal(model);
      expect(text, contains('Dry Clean'));
      expect(text, contains('SO-THERM'));
    });
  });

  group('UserModel', () {
    test('fromJson maps permissions list', () {
      final user = UserModel.fromJson({
        'id': 2,
        'uuid': 'u-2',
        'username': 'cashier',
        'full_name': 'Cashier',
        'email': 'c@x.com',
        'role': 'cashier',
        'permissions': ['sales.create', 'sales.read'],
      });
      expect(user.username, 'cashier');
      expect(user.permissions, contains('sales.create'));
    });

    test('fromJson defaults permissions to empty', () {
      final user = UserModel.fromJson({
        'id': 1,
        'uuid': 'u-1',
        'username': 'admin',
        'full_name': 'Admin',
        'email': 'a@x.com',
        'role': 'administrator',
      });
      expect(user.permissions, isEmpty);
    });
  });
}
