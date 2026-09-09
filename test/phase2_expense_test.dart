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
  Future<Map<String, dynamic>> salesSummary({String? from, String? to, int? branchId, int? userId, int? customerId}) async => {
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

  @override
  Future<Map<String, dynamic>> dashboardKpis({String? date}) async => {
        'today_sales': 1000,
        'today_collection': 800,
        'outstanding': 200,
        'ready_orders': 5,
      };

  @override
  Future<Map<String, dynamic>> operationalPnl({String? from, String? to}) async => {
        'gross_sales': 10000,
        'collections': 9000,
        'expenses': 2000,
        'net': 8000,
      };

  @override
  Future<Map<String, dynamic>> agingReport() async => {
        'days_30': 500,
        'days_60': 100,
        'days_90': 0,
        'days_90_plus': 0,
      };

  @override
  Future<Map<String, dynamic>> paymentMethodBreakdown({String? from, String? to}) async => {
        'cash': 5000,
        'card': 4000,
      };

  @override
  Future<Map<String, dynamic>> purchasingReport({String? from, String? to}) async => {};

  @override
  Future<Map<String, dynamic>> deliveryReport({String? from, String? to}) async => {};
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
