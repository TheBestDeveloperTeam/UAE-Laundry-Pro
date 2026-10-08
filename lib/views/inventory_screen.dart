import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/inventory_service.dart';
import 'package:laundrypro_uae/widgets/app_data_table.dart';
import 'package:laundrypro_uae/widgets/app_form_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, this.inventoryService});

  final InventoryService? inventoryService;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late final InventoryService _inventory;
  List<Map<String, dynamic>> _movements = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inventory = widget.inventoryService ?? InventoryService();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _inventory.listMovements();
      if (mounted) {
        setState(() => _movements = items);
      }
    } catch (e, stack) {
      AppLogger.error('Failed to load inventory movements', tag: 'InventoryScreen', error: e, stackTrace: stack);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _showReceiptDialog() async {
    final qtyController = TextEditingController();
    final costController = TextEditingController();
    final productIdController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AppFormDialog(
        title: context.l10n.t('inventory_receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: productIdController,
              decoration: InputDecoration(labelText: context.l10n.t('product_id')),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              decoration: InputDecoration(labelText: context.l10n.t('quantity')),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costController,
              decoration: InputDecoration(labelText: context.l10n.t('unit_cost')),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        onSave: () async {
          final pid = int.tryParse(productIdController.text) ?? 1;
          final qty = double.tryParse(qtyController.text) ?? 1.0;
          final cost = double.tryParse(costController.text) ?? 0.0;
          try {
            await _inventory.receipt({
              'product_id': pid,
              'quantity': qty,
              'unit_cost': cost,
            });
            if (ctx.mounted) {
              Navigator.of(ctx).pop();
            }
            _load();
          } catch (e, stack) {
            AppLogger.error('Failed to submit inventory receipt', tag: 'InventoryScreen', error: e, stackTrace: stack);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _movements.where((m) {
      final q = _searchController.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      final name = (m['product_name'] ?? '').toString().toLowerCase();
      final id = (m['product_id'] ?? m['id'] ?? '').toString();
      return name.contains(q) || id.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.t('inventory_management')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: context.l10n.t('inventory_receipt'),
            onPressed: _showReceiptDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.l10n.t('search_movements'),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AppDataTable(
                columns: [
                  AppDataTableColumn(
                    label: context.l10n.t('id'),
                    cellBuilder: (row) => Text(row['id']?.toString() ?? '-'),
                  ),
                  AppDataTableColumn(
                    label: context.l10n.t('product'),
                    cellBuilder: (row) => Text(row['product_name']?.toString() ?? 'ID: ${row['product_id'] ?? '-' }'),
                  ),
                  AppDataTableColumn(
                    label: context.l10n.t('type'),
                    cellBuilder: (row) => Text(row['movement_type']?.toString() ?? 'RECEIPT'),
                  ),
                  AppDataTableColumn(
                    label: context.l10n.t('quantity'),
                    numeric: true,
                    cellBuilder: (row) => Text(row['quantity']?.toString() ?? '0'),
                  ),
                  AppDataTableColumn(
                    label: context.l10n.t('date'),
                    cellBuilder: (row) => Text(row['created_at']?.toString() ?? '-'),
                  ),
                ],
                data: filtered,
                isLoading: _loading,
                emptyMessage: context.l10n.t('no_inventory_data'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
