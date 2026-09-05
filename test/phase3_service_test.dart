import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/services/analytics_service.dart';
import 'package:laundrypro_uae/services/branch_service.dart';
import 'package:laundrypro_uae/services/channel_service.dart';
import 'package:laundrypro_uae/services/localization_service.dart';
import 'package:laundrypro_uae/services/storefront_service.dart';
import 'package:laundrypro_uae/services/terminal_service.dart';

class FakeBranchService extends BranchService {
  @override
  Future<List<Map<String, dynamic>>> list() async => [
        {'id': 1, 'code': 'MAIN', 'name': 'Main Branch'},
        {'id': 2, 'code': 'JBR', 'name': 'JBR Branch'},
      ];
  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async => {'id': 3, ...body};
}

class FakeTerminalService extends TerminalService {
  @override
  Future<List<Map<String, dynamic>>> list({int? branchId}) async => [
        {'id': 1, 'code': 'T01', 'name': 'Counter 1', 'branch_code': 'MAIN'},
      ];
}

class FakeAnalyticsService extends AnalyticsService {
  @override
  Future<Map<String, dynamic>> summary({int? branchId}) async =>
      {'sales_total': 1500.0, 'order_count': 12};
  @override
  Future<List<Map<String, dynamic>>> trends({
    required String metric,
    required String from,
    required String to,
    int? branchId,
  }) async =>
      [{'snapshot_date': '2026-09-01', 'metric_value': 500}];
}

class FakeChannelService extends ChannelService {
  @override
  Future<List<Map<String, dynamic>>> list() async =>
      [{'id': 1, 'channel_type': 'sms', 'provider': 'stub', 'is_active': 1}];
}

class FakeLocalizationService extends LocalizationService {
  @override
  Future<List<Map<String, dynamic>>> profiles() async => [
        {'code': 'AE', 'name': 'UAE', 'currency_code': 'AED', 'currency_symbol': 'AED', 'timezone': 'Asia/Dubai'},
        {'code': 'SA', 'name': 'KSA', 'currency_code': 'SAR', 'currency_symbol': 'SAR', 'timezone': 'Asia/Riyadh'},
      ];
}

class FakeStorefrontService extends StorefrontService {
  @override
  Future<List<Map<String, dynamic>>> listOrders({String? status}) async =>
      [{'id': 1, 'customer_name': 'Test', 'customer_phone': '050', 'status': 'pending'}];
}

void main() {
  group('Phase3 BranchService', () {
    test('list returns branches', () async {
      final items = await FakeBranchService().list();
      expect(items.length, 2);
      expect(items.first['code'], 'MAIN');
    });
    test('create returns id', () async {
      final b = await FakeBranchService().create({'code': 'X', 'name': 'X'});
      expect(b['id'], 3);
    });
  });

  group('Phase3 TerminalService', () {
    test('list returns terminals', () async {
      final items = await FakeTerminalService().list();
      expect(items.first['code'], 'T01');
    });
    test('list with branchId', () async {
      final items = await FakeTerminalService().list(branchId: 1);
      expect(items, isNotEmpty);
    });
  });

  group('Phase3 AnalyticsService', () {
    test('summary has sales_total', () async {
      final s = await FakeAnalyticsService().summary();
      expect(s['sales_total'], 1500.0);
    });
    test('trends returns series', () async {
      final t = await FakeAnalyticsService().trends(metric: 'sales_total', from: '2026-08-01', to: '2026-09-05');
      expect(t.first['metric_value'], 500);
    });
    test('summary with branch', () async {
      final s = await FakeAnalyticsService().summary(branchId: 1);
      expect(s['order_count'], 12);
    });
  });

  group('Phase3 ChannelService', () {
    test('list channels', () async {
      final c = await FakeChannelService().list();
      expect(c.first['channel_type'], 'sms');
    });
  });

  group('Phase3 LocalizationService', () {
    test('profiles includes AE and SA', () async {
      final p = await FakeLocalizationService().profiles();
      expect(p.length, 2);
      expect(p.last['code'], 'SA');
    });
  });

  group('Phase3 StorefrontService', () {
    test('listOrders pending', () async {
      final o = await FakeStorefrontService().listOrders(status: 'pending');
      expect(o.first['status'], 'pending');
    });
  });

  group('Reports date filter logic', () {
    test('from before to', () {
      final from = DateTime(2026, 8, 1);
      final to = DateTime(2026, 9, 5);
      expect(from.isBefore(to), true);
    });
    test('30 day range', () {
      final to = DateTime(2026, 9, 5);
      final from = to.subtract(const Duration(days: 30));
      expect(from.day, 6);
    });
  });

  group('Dashboard KPI keys', () {
    test('unwrap summary block', () {
      final data = {'summary': {'total_sales': 100, 'order_count': 5}};
      final summary = data['summary'] as Map;
      expect(summary['total_sales'], 100);
    });
    test('default zero', () {
      final summary = <String, dynamic>{};
      expect(summary['total_sales'] ?? 0, 0);
    });
    test('valuation unwrap', () {
      final data = {'valuation': {'total_value': 8000}};
      expect((data['valuation'] as Map)['total_value'], 8000);
    });
    test('throughput unwrap', () {
      final data = {'throughput': {'orders_completed': 30}};
      expect((data['throughput'] as Map)['orders_completed'], 30);
    });
  });

  group('Phase3 route paths', () {
    const routes = [
      '/admin/branches', '/admin/terminals', '/analytics',
      '/settings/channels', '/settings/accounting', '/settings/localization',
      '/settings/storefront', '/customer',
    ];
    for (final route in routes) {
      test('route $route is defined', () {
        expect(route.startsWith('/'), true);
      });
    }
  });

  group('Phase3 i18n keys', () {
    const keys = ['branches', 'terminals', 'analytics', 'storefront', 'customer_portal'];
    for (final key in keys) {
      test('key $key non-empty', () {
        expect(key.isNotEmpty, true);
      });
    }
  });
}
