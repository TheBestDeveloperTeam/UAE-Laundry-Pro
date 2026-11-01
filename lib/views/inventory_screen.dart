import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/inventory_service.dart';
import 'package:laundrypro_uae/widgets/app_data_table.dart';
import 'package:laundrypro_uae/widgets/app_form_dialog.dart';
import 'package:laundrypro_uae/widgets/status_badge.dart';

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
      backgroundColor: AppTokens.canvas,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space24, vertical: AppTokens.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.t('inventory_management'), style: AppTokens.pageHeading),
                    const SizedBox(height: 2),
                    Text(
                      '${_movements.length} logged stock receipts, issues, and adjustments',
                      style: const TextStyle(fontSize: 13, color: AppTokens.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppTokens.textSecondary),
                  onPressed: _load,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space16),

            // Search Bar & Action
            Container(
              padding: const EdgeInsets.all(AppTokens.space12),
              decoration: AppTokens.cardDecoration,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: context.l10n.t('search_movements'),
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppTokens.textMuted),
                        filled: true,
                        fillColor: AppTokens.surfaceSubtle,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.borderSubtle)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.borderSubtle)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.brandTeal)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: AppTokens.space16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTokens.brandTeal, foregroundColor: Colors.white, elevation: 0),
                    onPressed: _showReceiptDialog,
                    icon: const Icon(Icons.add_box_outlined, size: 18),
                    label: Text(context.l10n.t('inventory_receipt'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space16),

            // Movements Table
            Expanded(
              child: Container(
                decoration: AppTokens.cardDecoration,
                clipBehavior: Clip.antiAlias,
                child: AppDataTable(
                  columns: [
                    AppDataTableColumn(
                      label: context.l10n.t('id'),
                      cellBuilder: (row) => Text(row['id']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    AppDataTableColumn(
                      label: context.l10n.t('product'),
                      cellBuilder: (row) => Text(row['product_name']?.toString() ?? 'ID: ${row['product_id'] ?? '-' }'),
                    ),
                    AppDataTableColumn(
                      label: context.l10n.t('type'),
                      cellBuilder: (row) {
                        final type = row['movement_type']?.toString().toUpperCase() ?? 'RECEIPT';
                        return StatusBadge(
                          label: type,
                          stage: type == 'RECEIPT' ? OrderStage.ready : OrderStage.washing,
                          compact: true,
                        );
                      },
                    ),
                    AppDataTableColumn(
                      label: context.l10n.t('quantity'),
                      numeric: true,
                      cellBuilder: (row) => Text(row['quantity']?.toString() ?? '0', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    AppDataTableColumn(
                      label: context.l10n.t('date'),
                      cellBuilder: (row) => Text(row['created_at']?.toString() ?? '-', style: const TextStyle(color: AppTokens.textMuted)),
                    ),
                  ],
                  data: filtered,
                  isLoading: _loading,
                  emptyMessage: context.l10n.t('no_inventory_data'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
