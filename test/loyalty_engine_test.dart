import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:laundrypro_uae/services/loyalty_engine.dart';
import 'package:laundrypro_uae/peripherals/core/storage/local_business_database.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Customer Loyalty Engine Tests', () {
    test('calculateTierForSpend maps AED thresholds accurately', () {
      expect(LoyaltyEngine.calculateTierForSpend(100.0), LoyaltyEngine.tierBronze);
      expect(LoyaltyEngine.calculateTierForSpend(350.0), LoyaltyEngine.tierSilver);
      expect(LoyaltyEngine.calculateTierForSpend(1200.0), LoyaltyEngine.tierGold);
      expect(LoyaltyEngine.calculateTierForSpend(4500.0), LoyaltyEngine.tierPlatinum);
    });

    test('getTierDiscountPercent returns expected discount', () {
      expect(LoyaltyEngine.getTierDiscountPercent('Bronze'), 0.0);
      expect(LoyaltyEngine.getTierDiscountPercent('Silver'), 0.05);
      expect(LoyaltyEngine.getTierDiscountPercent('Gold'), 0.10);
      expect(LoyaltyEngine.getTierDiscountPercent('Platinum'), 0.15);
    });

    test('recalculateCustomerLoyalty calculates rolling 90-day spend and updates SQLite', () async {
      final db = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: (db, _) async {
        await LocalBusinessDatabase.createSchema(db);
      });

      // Insert test customer
      await db.insert('customers', {
        'uuid': 'cust-test-01',
        'name': 'Rashid Al Maktoum',
        'phone': '0509998877',
        'loyalty_tier': 'Bronze',
        'loyalty_points': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      const custId = 1;

      // Insert 2 orders within 90 days total AED 1,200 (Gold tier)
      await db.insert('orders', {
        'uuid': 'ord-01',
        'order_number': 'LP-9001',
        'customer_id': custId,
        'customer_name': 'Rashid Al Maktoum',
        'status': 'ready',
        'payment_status': 'paid',
        'subtotal': 1142.86,
        'vat_amount': 57.14,
        'grand_total': 1200.00,
        'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      });

      final result = await LoyaltyEngine.recalculateCustomerLoyalty(db, custId);

      expect(result['loyalty_tier'], LoyaltyEngine.tierGold);
      expect(result['rolling_spend_90d'], 1200.00);
      expect(result['loyalty_points'], 120);
      expect(result['discount_percent'], 0.10);

      // Verify row updated in db
      final updated = await db.query('customers', where: 'id = ?', whereArgs: [custId]);
      expect(updated.first['loyalty_tier'], 'Gold');
      expect(updated.first['loyalty_points'], 120);

      await db.close();
    });
  });
}

