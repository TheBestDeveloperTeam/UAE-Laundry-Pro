import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/services/expense_service.dart';
import 'package:laundrypro_uae/services/notification_service.dart';
import 'package:laundrypro_uae/services/reports_service.dart';

class FakeExpenseService extends ExpenseService {
  @override
  Future<List<Map<String, dynamic>>> list({String? status, String? from, String? to}) async => [
        {'id': 1, 'description': 'Rent', 'amount': '5000', 'status': 'approved'},
        {'id': 2, 'description': 'Utilities', 'amount': '800', 'status': 'pending'},
      ];

  @override
  Future<List<Map<String, dynamic>>> listCategories() async => [
        {'id': 1, 'name': 'Overhead'},
      ];
}

class FakeNotificationService extends NotificationService {
  @override
  Future<List<Map<String, dynamic>>> list({bool unreadOnly = false}) async => [
        {'id': 1, 'title': 'Low Stock', 'message': 'Detergent below threshold', 'is_read': false},
        {'id': 2, 'title': 'Payroll Due', 'message': 'Run payroll for September', 'is_read': true},
      ];
}

class FakeReportsService extends ReportsService {
  @override
  Future<Map<String, dynamic>> salesSummary({String? from, String? to}) async => {
        'summary': {'total_sales': 12000, 'order_count': 45},
        'from': '2026-08-01',
        'to': '2026-09-01',
      };

  @override
  Future<Map<String, dynamic>> expensesSummary({String? from, String? to}) async => {
        'summary': {'total_expenses': 3000},
      };

  @override
  Future<Map<String, dynamic>> payrollSummary({String? from, String? to}) async => {
        'summary': {'total_payroll': 15000},
      };

  @override
  Future<Map<String, dynamic>> inventoryValuation() async => {
        'valuation': {'total_value': 8000},
      };

  @override
  Future<Map<String, dynamic>> productionThroughput({String? from, String? to}) async => {
        'throughput': {'orders_completed': 30},
      };
}

void main() {
  group('FakeExpenseService', () {
    test('returns expenses with statuses', () async {
      final items = await FakeExpenseService().list();
      expect(items.length, 2);
      expect(items.first['description'], 'Rent');
    });

    test('returns categories with id', () async {
      final cats = await FakeExpenseService().listCategories();
      expect(cats.first['name'], 'Overhead');
    });
  });

  group('FakeNotificationService', () {
    test('returns unread and read notifications', () async {
      final items = await FakeNotificationService().list();
      expect(items.first['title'], 'Low Stock');
      expect(items.last['is_read'], true);
    });
  });

  group('FakeReportsService', () {
    test('salesSummary returns summary block', () async {
      final data = await FakeReportsService().salesSummary();
      expect(data['summary'], isNotNull);
    });

    test('expensesSummary returns summary block', () async {
      final data = await FakeReportsService().expensesSummary();
      expect(data['summary'], isNotNull);
    });

    test('payrollSummary returns summary block', () async {
      final data = await FakeReportsService().payrollSummary();
      expect(data['summary'], isNotNull);
    });

    test('inventoryValuation returns valuation key', () async {
      final data = await FakeReportsService().inventoryValuation();
      expect(data['valuation'], isNotNull);
    });

    test('productionThroughput returns throughput key', () async {
      final data = await FakeReportsService().productionThroughput();
      expect(data['throughput'], isNotNull);
    });
  });
}
