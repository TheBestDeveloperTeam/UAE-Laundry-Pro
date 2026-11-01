import 'package:laundrypro_uae/models/customer_model.dart';
import 'package:laundrypro_uae/peripherals/core/storage/app_database.dart';
import 'package:laundrypro_uae/services/api_client.dart';
import 'package:laundrypro_uae/services/customer_service.dart';

class OfflineFirstCustomerService extends CustomerService {
  OfflineFirstCustomerService({ApiClient? apiClient, AppDatabase? database})
      : _database = database,
        super(apiClient: apiClient);

  final AppDatabase? _database;

  @override
  Future<List<CustomerModel>> list({String? query}) async {
    try {
      return await super.list(query: query);
    } catch (_) {
      final db = _database?.db;
      if (db != null && db.isOpen) {
        List<Map<String, dynamic>> rows;
        if (query != null && query.isNotEmpty) {
          final wild = '%$query%';
          rows = await db.rawQuery(
            'SELECT * FROM customers WHERE name LIKE ? OR phone LIKE ? ORDER BY id DESC',
            [wild, wild],
          );
        } else {
          rows = await db.rawQuery('SELECT * FROM customers ORDER BY id DESC LIMIT 100');
        }
        return rows.map((r) => CustomerModel.fromJson(r)).toList();
      }
      return [];
    }
  }

  @override
  Future<CustomerModel> create(Map<String, dynamic> body) async {
    try {
      return await super.create(body);
    } catch (_) {
      final db = _database?.db;
      if (db != null && db.isOpen) {
        final id = await db.insert('customers', {
          'uuid': 'CUST-${DateTime.now().millisecondsSinceEpoch}',
          'name': body['name'] ?? 'New Customer',
          'phone': body['phone'],
          'email': body['email'],
          'trn': body['trn'],
          'balance': 0.0,
          'loyalty_points': 0,
          'loyalty_tier': 'Bronze',
          'address': body['address'],
          'created_at': DateTime.now().toIso8601String(),
        });
        final row = await db.query('customers', where: 'id = ?', whereArgs: [id]);
        return CustomerModel.fromJson(row.first);
      }
      rethrow;
    }
  }
}

