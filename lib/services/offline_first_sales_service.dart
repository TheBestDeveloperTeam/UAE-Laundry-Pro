import 'package:laundrypro_uae/models/order_model.dart';
import 'package:laundrypro_uae/models/service_model.dart';
import 'package:laundrypro_uae/peripherals/core/storage/app_database.dart';
import 'package:laundrypro_uae/services/api_client.dart';
import 'package:laundrypro_uae/services/sales_service.dart';

class OfflineFirstSalesService extends SalesService {
  OfflineFirstSalesService({ApiClient? apiClient, AppDatabase? database})
      : _database = database,
        super(apiClient: apiClient, database: database);

  final AppDatabase? _database;

  @override
  Future<List<ServiceModel>> loadServices() async {
    try {
      return await super.loadServices();
    } catch (_) {
      final db = _database?.db;
      if (db != null && db.isOpen) {
        final rows = await db.rawQuery('SELECT * FROM services WHERE is_active = 1');
        return rows.map((r) => ServiceModel.fromJson(r)).toList();
      }
      return [];
    }
  }

  @override
  Future<List<OrderModel>> list({String? status, String? paymentStatus, int? limit, int? offset}) async {
    try {
      return await super.list(status: status, paymentStatus: paymentStatus, limit: limit, offset: offset);
    } catch (_) {
      final db = _database?.db;
      if (db != null && db.isOpen) {
        String query = 'SELECT * FROM orders';
        final conditions = <String>[];
        final args = <dynamic>[];

        if (status != null && status.isNotEmpty) {
          conditions.add('status = ?');
          args.add(status.toLowerCase());
        }
        if (paymentStatus != null && paymentStatus.isNotEmpty) {
          conditions.add('payment_status = ?');
          args.add(paymentStatus.toLowerCase());
        }

        if (conditions.isNotEmpty) {
          query += ' WHERE ${conditions.join(' AND ')}';
        }

        query += ' ORDER BY id DESC';

        if (limit != null) {
          query += ' LIMIT $limit';
          if (offset != null) {
            query += ' OFFSET $offset';
          }
        } else {
          query += ' LIMIT 100';
        }

        final rows = await db.rawQuery(query, args);
        return rows.map((r) => OrderModel.fromJson(r)).toList();
      }
      return [];
    }
  }

  @override
  Future<OrderModel> getOrder(int orderId) async {
    try {
      return await super.getOrder(orderId);
    } catch (_) {
      final db = _database?.db;
      if (db != null && db.isOpen) {
        final rows = await db.query('orders', where: 'id = ?', whereArgs: [orderId]);
        if (rows.isNotEmpty) {
          return OrderModel.fromJson(rows.first);
        }
      }
      rethrow;
    }
  }
}

