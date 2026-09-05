import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/core/document_renderer.dart';
import 'package:laundrypro_uae/services/challan_service.dart';
import 'package:laundrypro_uae/services/delivery_service.dart';
import 'package:laundrypro_uae/services/purchase_service.dart';
import 'package:laundrypro_uae/services/sales_service.dart';

class FakeSalesService extends SalesService {
  FakeSalesService(this.orders);
  final List<Map<String, dynamic>> orders;

  @override
  Future<List<Map<String, dynamic>>> list({String? status, String? paymentStatus}) async => orders;
}

class FakeDeliveryService extends DeliveryService {
  @override
  Future<List<Map<String, dynamic>>> list({String? status, int? salesOrderId}) async => [
        {'id': 1, 'sales_order_id': 10, 'status': 'pending', 'delivery_address': 'Dubai'},
      ];
}

class FakeChallanService extends ChallanService {
  @override
  Future<List<Map<String, dynamic>>> list({String? challanType}) async => [
        {'challan_no': 'CH-001', 'challan_type': 'delivery', 'status': 'issued', 'lines': []},
      ];
}

class FakePurchaseService extends PurchaseService {
  @override
  Future<List<Map<String, dynamic>>> list({String? status}) async => [
        {'po_no': 'PO-001', 'vendor_id': 2, 'status': 'draft'},
      ];
}

void main() {
  group('ChallanModel', () {
    test('fromMap parses lines and reference', () {
      final model = ChallanModel.fromMap({
        'challan_no': 'CH-100',
        'challan_type': 'delivery',
        'status': 'issued',
        'reference_type': 'sales_order',
        'reference_id': 5,
        'lines': [
          {'description': 'Shirt', 'quantity': 3},
        ],
      });
      expect(model.challanNo, 'CH-100');
      expect(model.lines.length, 1);
      expect(model.referenceId, 5);
    });

    test('thermal output includes challan number and lines', () {
      final model = ChallanModel.fromMap({
        'challan_no': 'CH-200',
        'challan_type': 'delivery',
        'status': 'issued',
        'lines': [{'description': 'Trousers', 'quantity': 2}],
      });
      final text = DocumentRenderer.toThermal(model);
      expect(text, contains('CH-200'));
      expect(text, contains('Trousers'));
    });

    test('PDF bytes are non-empty', () async {
      final model = ChallanModel.fromMap({
        'challan_no': 'CH-300',
        'challan_type': 'delivery',
        'status': 'issued',
        'lines': [],
      });
      final pdf = await DocumentRenderer.toA4Pdf(model);
      expect(pdf.isNotEmpty, true);
    });

    test('line quantity parses numeric strings', () {
      final line = ChallanLine.fromMap({'description': 'Towel', 'quantity': '2.5'});
      expect(line.quantity, 2.5);
    });
  });

  group('FakeSalesService', () {
    test('returns injected orders', () async {
      final service = FakeSalesService([
        {'id': 1, 'order_no': 'SO-001', 'status': 'received'},
      ]);
      final items = await service.list(status: 'received');
      expect(items.first['order_no'], 'SO-001');
    });

    test('returns empty list when configured', () async {
      final items = await FakeSalesService([]).list();
      expect(items, isEmpty);
    });
  });

  group('FakeDeliveryService', () {
    test('returns delivery task with sales order id', () async {
      final items = await FakeDeliveryService().list();
      expect(items.first['sales_order_id'], 10);
    });
  });

  group('FakeChallanService', () {
    test('returns challan number', () async {
      final items = await FakeChallanService().list(challanType: 'delivery');
      expect(items.first['challan_no'], 'CH-001');
    });
  });

  group('FakePurchaseService', () {
    test('returns purchase order number', () async {
      final items = await FakePurchaseService().list();
      expect(items.first['po_no'], 'PO-001');
    });
  });
}
