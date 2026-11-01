import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/catalog_service.dart';
import 'package:laundrypro_uae/widgets/app_data_table.dart';
import 'package:laundrypro_uae/widgets/app_form_dialog.dart';
import 'package:laundrypro_uae/widgets/status_badge.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, this.catalogService});

  final CatalogService? catalogService;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> with SingleTickerProviderStateMixin {
  late final CatalogService _catalog;
  late final TabController _tabs;

  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String _searchFilter = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _catalog = widget.catalogService ?? CatalogService();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final services = await _catalog.listServices();
      final products = await _catalog.listProducts();
      if (mounted) {
        setState(() {
          _services = services;
          _products = products;
        });
      }
    } catch (e, stack) {
      AppLogger.error('Failed to load catalog services/products', tag: 'CatalogScreen', error: e, stackTrace: stack);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _showServiceDialog([Map<String, dynamic>? existing]) {
    final isNew = existing == null;
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final codeCtrl = TextEditingController(text: existing?['code']?.toString() ?? '');
    final rateCtrl = TextEditingController(text: existing?['base_rate']?.toString() ?? '10.00');

    showDialog(
      context: context,
      builder: (ctx) => AppFormDialog(
        title: isNew ? 'New Service' : 'Edit Service',
        onSave: () async {
          final data = {
            'name': nameCtrl.text.trim(),
            'code': codeCtrl.text.trim(),
            'base_rate': double.tryParse(rateCtrl.text) ?? 0.0,
            'is_group': false,
            'status': 'active',
          };
          if (isNew) {
            await _catalog.createService(data);
          } else {
            await _catalog.updateService(existing['id'] as int, data);
          }
          if (ctx.mounted) Navigator.pop(ctx);
          await _load();
        },
        content: Column(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
            const SizedBox(height: 16),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code / SKU')),
            const SizedBox(height: 16),
            TextField(controller: rateCtrl, decoration: const InputDecoration(labelText: 'Base Rate (AED) *'), keyboardType: TextInputType.number),
          ],
        ),
      ),
    );
  }

  void _showProductDialog([Map<String, dynamic>? existing]) {
    final isNew = existing == null;
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final rateCtrl = TextEditingController(text: existing?['base_rate']?.toString() ?? '10.00');

    showDialog(
      context: context,
      builder: (ctx) => AppFormDialog(
        title: isNew ? 'New Product' : 'Edit Product',
        onSave: () async {
          final data = {
            'name': nameCtrl.text.trim(),
            'base_rate': double.tryParse(rateCtrl.text) ?? 0.0,
          };
          if (isNew) {
            await _catalog.createProduct(data);
          } else {
            await _catalog.updateProduct(existing['id'] as int, data);
          }
          if (ctx.mounted) Navigator.pop(ctx);
          await _load();
        },
        content: Column(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name *')),
            const SizedBox(height: 16),
            TextField(controller: rateCtrl, decoration: const InputDecoration(labelText: 'Rate (AED) *'), keyboardType: TextInputType.number),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                    Text(l10n.t('catalog'), style: AppTokens.pageHeading),
                    const SizedBox(height: 2),
                    const Text(
                      'Manage garment care service catalog and retail inventory items',
                      style: TextStyle(fontSize: 13, color: AppTokens.textSecondary),
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

            // Tab Navigation Strip
            Container(
              decoration: BoxDecoration(
                color: AppTokens.surfacePrimary,
                borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                border: Border.all(color: AppTokens.borderSubtle),
              ),
              child: TabBar(
                controller: _tabs,
                labelColor: AppTokens.brandTeal,
                unselectedLabelColor: AppTokens.textSecondary,
                indicatorColor: AppTokens.brandTeal,
                tabs: [
                  Tab(text: l10n.t('services')),
                  Tab(text: l10n.t('products_inventory')),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space16),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildTab(
                    l10n.t('services'),
                    _services,
                    _showServiceDialog,
                    [
                      const AppDataTableColumn(label: 'Service Name', key: 'name'),
                      const AppDataTableColumn(label: 'SKU / Code', key: 'code'),
                      const AppDataTableColumn(label: 'Base Rate (AED)', key: 'base_rate', numeric: true),
                      AppDataTableColumn(
                        label: 'Status',
                        cellBuilder: (row) {
                          final status = row['status']?.toString().toLowerCase() ?? 'active';
                          return StatusBadge(
                            label: status.toUpperCase(),
                            stage: status == 'active' ? OrderStage.ready : OrderStage.cancelled,
                            compact: true,
                          );
                        },
                      ),
                    ],
                  ),
                  _buildTab(
                    l10n.t('products_inventory'),
                    _products,
                    _showProductDialog,
                    [
                      const AppDataTableColumn(label: 'Product Name', key: 'name'),
                      const AppDataTableColumn(label: 'Rate (AED)', key: 'base_rate', numeric: true),
                      const AppDataTableColumn(label: 'Stock Qty', key: 'stock_quantity', numeric: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, List<Map<String, dynamic>> items, void Function([Map<String, dynamic>?]) onAdd, List<AppDataTableColumn> cols) {
    final filtered = items.where((item) {
      if (_searchFilter.isEmpty) return true;
      final name = (item['name'] ?? '').toString().toLowerCase();
      final code = (item['code'] ?? '').toString().toLowerCase();
      return name.contains(_searchFilter) || code.contains(_searchFilter);
    }).toList();

    return Column(
      children: [
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
                    hintText: 'Search $title...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppTokens.textMuted),
                    filled: true,
                    fillColor: AppTokens.surfaceSubtle,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.borderSubtle)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.borderSubtle)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.brandTeal)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchFilter = val.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: AppTokens.space16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTokens.brandTeal, foregroundColor: Colors.white, elevation: 0),
                onPressed: () => onAdd(),
                icon: const Icon(Icons.add, size: 18),
                label: Text('New $title', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        Expanded(
          child: Container(
            decoration: AppTokens.cardDecoration,
            clipBehavior: Clip.antiAlias,
            child: AppDataTable(
              columns: cols,
              data: filtered,
              isLoading: _loading,
              onRowTap: (row) => onAdd(row as Map<String, dynamic>),
            ),
          ),
        ),
      ],
    );
  }
}
