import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';
import 'package:laundrypro_uae/peripherals/core/storage/app_database.dart';

class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({super.key, this.database});

  final AppDatabase? database;

  static Future<void> show(BuildContext context, {AppDatabase? database}) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) => GlobalSearchDialog(database: database),
    );
  }

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _orderResults = [];
  List<Map<String, dynamic>> _customerResults = [];
  List<Map<String, dynamic>> _inventoryResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _performSearch(''); // Show recent default results
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _performSearch(_queryController.text.trim());
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final db = widget.database?.db;
      if (db != null) {
        if (query.isEmpty) {
          // Default recent 5
          final orders = await db.rawQuery(
            'SELECT id, order_number, customer_name, grand_total, status FROM orders ORDER BY id DESC LIMIT 4'
          );
          final customers = await db.rawQuery(
            'SELECT id, name, phone, balance, loyalty_tier FROM customers ORDER BY id DESC LIMIT 4'
          );
          final inventory = await db.rawQuery(
            'SELECT id, name, sku, stock_quantity, category FROM inventory_items LIMIT 3'
          );

          if (mounted) {
            setState(() {
              _orderResults = orders;
              _customerResults = customers;
              _inventoryResults = inventory;
              _isLoading = false;
            });
          }
        } else {
          final wild = '%$query%';
          final orders = await db.rawQuery(
            'SELECT id, order_number, customer_name, grand_total, status FROM orders WHERE order_number LIKE ? OR customer_name LIKE ? OR customer_phone LIKE ? LIMIT 6',
            [wild, wild, wild],
          );
          final customers = await db.rawQuery(
            'SELECT id, name, phone, balance, loyalty_tier FROM customers WHERE name LIKE ? OR phone LIKE ? LIMIT 6',
            [wild, wild],
          );
          final inventory = await db.rawQuery(
            'SELECT id, name, sku, stock_quantity, category FROM inventory_items WHERE name LIKE ? OR sku LIKE ? LIMIT 6',
            [wild, wild],
          );

          if (mounted) {
            setState(() {
              _orderResults = orders;
              _customerResults = customers;
              _inventoryResults = inventory;
              _isLoading = false;
            });
          }
        }
      } else {
        // Fallback demo results if DB uninitialized
        setState(() {
          _orderResults = [
            {'order_number': 'LP-10482', 'customer_name': 'Aisha Khan', 'grand_total': 86.0, 'status': 'ready'},
            {'order_number': 'LP-10481', 'customer_name': 'Omar Hassan', 'grand_total': 145.0, 'status': 'finishing'},
          ];
          _customerResults = [
            {'name': 'Mohammed Al Nuaimi', 'phone': '0501234567', 'balance': 0.0, 'loyalty_tier': 'Silver'},
            {'name': 'Fatima Al Zarooni', 'phone': '0559876543', 'balance': 50.0, 'loyalty_tier': 'Gold'},
          ];
          _inventoryResults = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 80, left: 32, right: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 24,
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input Field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppTokens.brandTeal, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      focusNode: _focusNode,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        hintText: 'Search orders, customers, inventory...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_queryController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                      onPressed: () => _queryController.clear(),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text('ESC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

            // Search Results List
            Flexible(
              child: _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator(color: AppTokens.brandTeal)))
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        if (_orderResults.isNotEmpty) ...[
                          _buildSectionHeader('ORDERS', Icons.receipt_long_outlined),
                          ..._orderResults.map((ord) => _buildOrderTile(context, ord)),
                        ],
                        if (_customerResults.isNotEmpty) ...[
                          _buildSectionHeader('CUSTOMERS', Icons.person_outline_rounded),
                          ..._customerResults.map((c) => _buildCustomerTile(context, c)),
                        ],
                        if (_inventoryResults.isNotEmpty) ...[
                          _buildSectionHeader('INVENTORY ITEMS', Icons.inventory_2_outlined),
                          ..._inventoryResults.map((i) => _buildInventoryTile(context, i)),
                        ],
                        if (_orderResults.isEmpty && _customerResults.isEmpty && _inventoryResults.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No matching records found.',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),

            // Bottom Shortcut Guidance Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: const Row(
                children: [
                  Icon(Icons.keyboard_outlined, size: 16, color: Color(0xFF94A3B8)),
                  SizedBox(width: 8),
                  Text('Press Enter to view, Esc to dismiss', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  Spacer(),
                  Text('LaundryPro Global Search', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 18, top: 12, bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTile(BuildContext context, Map<String, dynamic> ord) {
    final num = ord['order_number'] ?? '';
    final cust = ord['customer_name'] ?? '';
    final total = ord['grand_total'] ?? 0.0;
    final status = (ord['status'] ?? '').toString().toUpperCase();

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.receipt_outlined, color: Color(0xFF2563EB), size: 18),
      ),
      title: Row(
        children: [
          Text(num, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A))),
          const SizedBox(width: 10),
          Text(cust, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
        ],
      ),
      subtitle: Text('Status: $status', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      trailing: Text('AED ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 13.5)),
      onTap: () {
        Navigator.of(context).pop();
        context.go('/pending');
      },
    );
  }

  Widget _buildCustomerTile(BuildContext context, Map<String, dynamic> c) {
    final name = c['name'] ?? '';
    final phone = c['phone'] ?? '';
    final tier = c['loyalty_tier'] ?? 'Bronze';

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.person_rounded, color: Color(0xFF059669), size: 18),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A))),
      subtitle: Text('$phone • $tier Tier', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
      onTap: () {
        Navigator.of(context).pop();
        context.go('/customers');
      },
    );
  }

  Widget _buildInventoryTile(BuildContext context, Map<String, dynamic> i) {
    final name = i['name'] ?? '';
    final sku = i['sku'] ?? '';
    final stock = i['stock_quantity'] ?? 0;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFD97706), size: 18),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A))),
      subtitle: Text('SKU: $sku • In Stock: $stock', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
      onTap: () {
        Navigator.of(context).pop();
        context.go('/inventory');
      },
    );
  }
}

