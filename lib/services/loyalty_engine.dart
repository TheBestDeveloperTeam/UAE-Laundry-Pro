import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Automated Customer Loyalty Engine for LaundryPro UAE
/// Handles rolling 90-day spend calculations and tier upgrades
/// Tier Thresholds (AED in 90 days):
/// - Platinum: >= AED 3,000 (15% discount perk)
/// - Gold:     >= AED 1,000 (10% discount perk)
/// - Silver:   >= AED 300   (5% discount perk)
/// - Bronze:   < AED 300    (Standard)
class LoyaltyEngine {
  const LoyaltyEngine._();

  static const String tierPlatinum = 'Platinum';
  static const String tierGold = 'Gold';
  static const String tierSilver = 'Silver';
  static const String tierBronze = 'Bronze';

  static double getTierDiscountPercent(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum':
        return 0.15;
      case 'gold':
        return 0.10;
      case 'silver':
        return 0.05;
      default:
        return 0.0;
    }
  }

  static String calculateTierForSpend(double spend90Days) {
    if (spend90Days >= 3000.0) {
      return tierPlatinum;
    } else if (spend90Days >= 1000.0) {
      return tierGold;
    } else if (spend90Days >= 300.0) {
      return tierSilver;
    }
    return tierBronze;
  }

  /// Recalculates loyalty tier and points for a given customer based on rolling order history
  static Future<Map<String, dynamic>> recalculateCustomerLoyalty(
    Database db,
    int customerId,
  ) async {
    // 1. Calculate sum of customer's spend over last 90 days
    final now = DateTime.now();
    final ninetyDaysAgo = now.subtract(const Duration(days: 90)).toIso8601String();

    final spendResult = await db.rawQuery('''
      SELECT COALESCE(SUM(grand_total), 0.0) as total_spend, COUNT(*) as order_count
      FROM orders
      WHERE customer_id = ? AND status != 'cancelled' AND created_at >= ?
    ''', [customerId, ninetyDaysAgo]);

    final double rollingSpend = (spendResult.first['total_spend'] as num?)?.toDouble() ?? 0.0;
    final int orderCount = (spendResult.first['order_count'] as int?) ?? 0;

    // 2. Determine new loyalty tier
    final newTier = calculateTierForSpend(rollingSpend);

    // 3. 1 point for every AED 10 spent
    final earnedPoints = (rollingSpend / 10).floor();

    // 4. Persist updated tier and points to database
    await db.rawUpdate('''
      UPDATE customers 
      SET loyalty_tier = ?, loyalty_points = ?
      WHERE id = ?
    ''', [newTier, earnedPoints, customerId]);

    return {
      'customer_id': customerId,
      'rolling_spend_90d': rollingSpend,
      'order_count_90d': orderCount,
      'loyalty_tier': newTier,
      'loyalty_points': earnedPoints,
      'discount_percent': getTierDiscountPercent(newTier),
    };
  }

  /// Batch recalculation for all active customers
  static Future<int> recalculateAllCustomers(Database db) async {
    final customers = await db.rawQuery('SELECT id FROM customers');
    for (final row in customers) {
      final id = row['id'] as int?;
      if (id != null) {
        await recalculateCustomerLoyalty(db, id);
      }
    }
    return customers.length;
  }
}

