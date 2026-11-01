import 'dart:math';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalBusinessDatabase {
  static const int version = 1;

  static Future<void> createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        trn TEXT,
        balance REAL DEFAULT 0.0,
        loyalty_points INTEGER DEFAULT 0,
        loyalty_tier TEXT DEFAULT 'Bronze',
        address TEXT,
        created_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        unit TEXT DEFAULT 'pcs',
        turnaround_hours INTEGER DEFAULT 24,
        is_active INTEGER DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        order_number TEXT UNIQUE NOT NULL,
        customer_id INTEGER,
        customer_name TEXT,
        customer_phone TEXT,
        status TEXT NOT NULL,
        payment_status TEXT NOT NULL,
        subtotal REAL NOT NULL,
        vat_amount REAL NOT NULL,
        discount_total REAL DEFAULT 0.0,
        grand_total REAL NOT NULL,
        balance_due REAL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        promised_date TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        service_id INTEGER,
        service_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
        FOREIGN KEY (service_id) REFERENCES services (id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        reference TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        stock_quantity INTEGER NOT NULL DEFAULT 0,
        reorder_level INTEGER NOT NULL DEFAULT 10,
        unit_cost REAL NOT NULL DEFAULT 0.0
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        department TEXT NOT NULL,
        phone TEXT,
        salary REAL NOT NULL,
        status TEXT DEFAULT 'active'
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        status TEXT DEFAULT 'approved',
        created_at TEXT NOT NULL
      );
    ''');

    // Indexes for fast search and aggregation
    await db.execute('CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name);');
  }

  /// Seeds 1000+ realistic, linked, relational business records if the database is unseeded
  static Future<void> seedIfEmpty(Database db) async {
    final countRes = await db.rawQuery('SELECT COUNT(*) as count FROM orders');
    final count = countRes.isNotEmpty ? (countRes.first['count'] as int? ?? 0) : 0;
    if (count >= 100) {
      return; // Already seeded
    }

    final rand = Random(42); // Deterministic generation seed

    // 1. Seed Services / Catalog
    final initialServices = [
      {'name': 'Wash & Fold', 'category': 'Laundry', 'price': 15.0, 'unit': 'kg', 'turnaround': 24},
      {'name': 'Dry Cleaning', 'category': 'Dry Clean', 'price': 25.0, 'unit': 'pcs', 'turnaround': 48},
      {'name': 'Abaya Premium Care', 'category': 'Traditional', 'price': 35.0, 'unit': 'pcs', 'turnaround': 24},
      {'name': 'Kandora Pressing', 'category': 'Traditional', 'price': 18.0, 'unit': 'pcs', 'turnaround': 12},
      {'name': 'Suit 2-Piece Express', 'category': 'Dry Clean', 'price': 55.0, 'unit': 'set', 'turnaround': 24},
      {'name': 'Silk & Delicate Dress', 'category': 'Delicates', 'price': 45.0, 'unit': 'pcs', 'turnaround': 48},
      {'name': 'Curtain & Drape Cleaning', 'category': 'Home', 'price': 65.0, 'unit': 'panel', 'turnaround': 72},
      {'name': 'Bedding & Duvet Heavy', 'category': 'Home', 'price': 40.0, 'unit': 'pcs', 'turnaround': 48},
      {'name': 'Sneakers & Shoes Restoration', 'category': 'Specialty', 'price': 50.0, 'unit': 'pair', 'turnaround': 48},
      {'name': 'Steam Press Only', 'category': 'Pressing', 'price': 10.0, 'unit': 'pcs', 'turnaround': 6},
    ];

    final serviceIds = <int>[];
    for (var i = 0; i < initialServices.length; i++) {
      final s = initialServices[i];
      final id = await db.insert('services', {
        'uuid': 'SRV-${(i + 1).toString().padLeft(3, '0')}',
        'name': s['name'],
        'category': s['category'],
        'price': s['price'],
        'unit': s['unit'],
        'turnaround_hours': s['turnaround'],
        'is_active': 1,
      });
      serviceIds.add(id);
    }

    // 2. Seed 120 Realistic UAE Customers
    final firstNames = ['Mohammed', 'Fatima', 'Ahmed', 'Aisha', 'Rashid', 'Mariam', 'Zayd', 'Noura', 'Hamad', 'Layla', 'Omar', 'Sara', 'Khalid', 'Hessa', 'Sultan', 'Reem', 'Mansoor', 'Shamsa', 'Ali', 'Dana'];
    final lastNames = ['Al Nuaimi', 'Al Zarooni', 'Al Falasi', 'Al Maktoum', 'Khan', 'Al Mazrouei', 'Hassan', 'Al Shamsi', 'Al Suwaidi', 'Patel', 'Al Marzooqi', 'Smith', 'Al Hashimi', 'Al Kaabi', 'Saeed', 'Al Blooshi'];
    final locations = ['Downtown Dubai', 'Dubai Marina', 'Jumeirah Beach Residence', 'Palm Jumeirah', 'Business Bay', 'Deira', 'Al Barsha', 'Khalidiya Abu Dhabi', 'Yas Island', 'Al Nahda Sharjah'];

    final customerIds = <int>[];
    for (var i = 1; i <= 120; i++) {
      final fname = firstNames[rand.nextInt(firstNames.length)];
      final lname = lastNames[rand.nextInt(lastNames.length)];
      final phone = '050${(1000000 + rand.nextInt(8999999))}';
      final tier = i % 10 == 0 ? 'Platinum' : (i % 4 == 0 ? 'Gold' : (i % 2 == 0 ? 'Silver' : 'Bronze'));
      final cid = await db.insert('customers', {
        'uuid': 'CUST-${i.toString().padLeft(4, '0')}',
        'name': '$fname $lname',
        'phone': phone,
        'email': '${fname.toLowerCase()}.${lname.replaceAll(' ', '').toLowerCase()}$i@example.ae',
        'trn': i % 8 == 0 ? '100${rand.nextInt(899999999)}00003' : null,
        'balance': (rand.nextDouble() * 200).roundToDouble(),
        'loyalty_points': rand.nextInt(850),
        'loyalty_tier': tier,
        'address': '${10 + rand.nextInt(90)}, Villa St, ${locations[rand.nextInt(locations.length)]}',
        'created_at': DateTime.now().subtract(Duration(days: 30 + rand.nextInt(180))).toIso8601String(),
      });
      customerIds.add(cid);
    }

    // 3. Seed 1,000+ Realistic Orders with Line Items & Payments
    final statuses = ['received', 'washing', 'finishing', 'ready', 'delivered'];
    final paymentMethods = ['Cash', 'Credit Card', 'Apple Pay', 'Tabby', 'Bank Transfer'];
    final now = DateTime.now();

    await db.transaction((txn) async {
      for (var orderNum = 1; orderNum <= 1024; orderNum++) {
        final custId = customerIds[rand.nextInt(customerIds.length)];
        final daysAgo = rand.nextInt(90);
        final hoursAgo = rand.nextInt(24);
        final orderDate = now.subtract(Duration(days: daysAgo, hours: hoursAgo));
        final promised = orderDate.add(const Duration(hours: 48));

        // Status logic depending on age
        String status;
        if (daysAgo == 0) {
          final pick = rand.nextInt(4);
          status = pick == 0 ? 'received' : (pick == 1 ? 'washing' : (pick == 2 ? 'finishing' : 'ready'));
        } else if (daysAgo <= 2) {
          status = rand.nextInt(2) == 0 ? 'ready' : 'delivered';
        } else {
          status = 'delivered';
        }

        // Calculate line items
        final itemCount = 1 + rand.nextInt(4);
        var subtotal = 0.0;
        final selectedItems = <Map<String, dynamic>>[];

        for (var k = 0; k < itemCount; k++) {
          final sIndex = rand.nextInt(initialServices.length);
          final srv = initialServices[sIndex];
          final qty = 1 + rand.nextInt(5);
          final price = srv['price'] as double;
          final total = qty * price;
          subtotal += total;
          selectedItems.add({
            'service_id': serviceIds[sIndex],
            'service_name': srv['name'],
            'quantity': qty,
            'unit_price': price,
            'total': total,
          });
        }

        final vat = (subtotal * 0.05).roundToDouble(); // 5% UAE VAT
        final grandTotal = subtotal + vat;

        // Payment status
        String payStatus;
        double balanceDue;
        if (status == 'delivered') {
          payStatus = 'paid';
          balanceDue = 0.0;
        } else if (rand.nextInt(5) == 0) {
          payStatus = 'unpaid';
          balanceDue = grandTotal;
        } else if (rand.nextInt(10) == 0) {
          payStatus = 'partial';
          balanceDue = (grandTotal / 2).roundToDouble();
        } else {
          payStatus = 'paid';
          balanceDue = 0.0;
        }

        final orderId = await txn.insert('orders', {
          'uuid': 'ORD-${orderNum.toString().padLeft(5, '0')}',
          'order_number': 'LP-${(10000 + orderNum)}',
          'customer_id': custId,
          'customer_name': 'Customer #$custId',
          'customer_phone': '050${(1000000 + custId)}',
          'status': status,
          'payment_status': payStatus,
          'subtotal': subtotal,
          'vat_amount': vat,
          'discount_total': 0.0,
          'grand_total': grandTotal,
          'balance_due': balanceDue,
          'created_at': orderDate.toIso8601String(),
          'promised_date': promised.toIso8601String(),
        });

        // Insert line items
        for (final item in selectedItems) {
          await txn.insert('order_items', {
            'order_id': orderId,
            'service_id': item['service_id'],
            'service_name': item['service_name'],
            'quantity': item['quantity'],
            'unit_price': item['unit_price'],
            'total': item['total'],
          });
        }

        // Insert payment if paid or partial
        if (payStatus == 'paid' || payStatus == 'partial') {
          final paidAmt = payStatus == 'paid' ? grandTotal : (grandTotal - balanceDue);
          await txn.insert('payments', {
            'order_id': orderId,
            'amount': paidAmt,
            'payment_method': paymentMethods[rand.nextInt(paymentMethods.length)],
            'reference': 'TXN-${100000 + rand.nextInt(900000)}',
            'created_at': orderDate.add(const Duration(minutes: 5)).toIso8601String(),
          });
        }
      }
    });

    // 4. Seed Inventory Items
    final inventorySeed = [
      {'sku': 'DET-001', 'name': 'Eco-Clean Liquid Detergent 25L', 'category': 'Chemicals', 'stock': 48, 'reorder': 15, 'cost': 120.0},
      {'sku': 'SFT-002', 'name': 'Oud Breeze Fabric Softener 20L', 'category': 'Chemicals', 'stock': 32, 'reorder': 10, 'cost': 95.0},
      {'sku': 'STN-003', 'name': 'Oxide Spot & Stain Remover 5L', 'category': 'Chemicals', 'stock': 12, 'reorder': 8, 'cost': 75.0},
      {'sku': 'HNG-004', 'name': 'Heavy Duty Wire Hangers 500pk', 'category': 'Packaging', 'stock': 140, 'reorder': 40, 'cost': 85.0},
      {'sku': 'BAG-005', 'name': 'Poly Garment Roll Bags 1000m', 'category': 'Packaging', 'stock': 25, 'reorder': 5, 'cost': 160.0},
      {'sku': 'TAG-006', 'name': 'Thermal Heat-Seal Garment Tags', 'category': 'Supplies', 'stock': 9500, 'reorder': 2000, 'cost': 0.15},
    ];

    for (final inv in inventorySeed) {
      await db.insert('inventory_items', {
        'sku': inv['sku'],
        'name': inv['name'],
        'category': inv['category'],
        'stock_quantity': inv['stock'],
        'reorder_level': inv['reorder'],
        'unit_cost': inv['cost'],
      });
    }

    // 5. Seed Staff Members
    final staffSeed = [
      {'name': 'Sarah Al Mansoori', 'role': 'Store Manager', 'dept': 'Management', 'salary': 12500.0, 'phone': '0501112233'},
      {'name': 'Mohammed Tariq', 'role': 'Lead Pressing Specialist', 'dept': 'Operations', 'salary': 5200.0, 'phone': '0502223344'},
      {'name': 'Kamal Perera', 'role': 'Dry Cleaning Master', 'dept': 'Operations', 'salary': 5800.0, 'phone': '0503334455'},
      {'name': 'Aisha Rahman', 'role': 'Cashier & POS Operator', 'dept': 'Front Desk', 'salary': 4500.0, 'phone': '0504445566'},
      {'name': 'David Olatunji', 'role': 'Logistics & Van Driver', 'dept': 'Delivery', 'salary': 4200.0, 'phone': '0505556677'},
    ];

    for (var i = 0; i < staffSeed.length; i++) {
      final st = staffSeed[i];
      await db.insert('employees', {
        'uuid': 'EMP-${(i + 1).toString().padLeft(3, '0')}',
        'name': st['name'],
        'role': st['role'],
        'department': st['dept'],
        'phone': st['phone'],
        'salary': st['salary'],
        'status': 'active',
      });
    }
  }
}
