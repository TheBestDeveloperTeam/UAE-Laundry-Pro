import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/catalog_service.dart';
import 'package:laundrypro_uae/widgets/app_data_table.dart';
import 'package:laundrypro_uae/widgets/app_form_dialog.dart';

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
    } catch (_) {}
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
        },
        onSuccess: _load,
        content: Column(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
            const SizedBox(height: 16),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code')),
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
        },
        onSuccess: _load,
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
      appBar: AppBar(
        title: Text(l10n.t('catalog')),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.t('services')),
            Tab(text: l10n.t('products_inventory')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildTab(
            l10n.t('services'),
            _services,
            _showServiceDialog,
            [
              const AppDataTableColumn(label: 'Name', key: 'name'),
              const AppDataTableColumn(label: 'Code', key: 'code'),
              const AppDataTableColumn(label: 'Base Rate', key: 'base_rate', numeric: true),
              AppDataTableColumn(label: 'Status', cellBuilder: (row) => Text(row['status'] ?? 'active')),
            ],
          ),
          _buildTab(
            l10n.t('products_inventory'),
            _products,
            _showProductDialog,
            [
              const AppDataTableColumn(label: 'Product Name', key: 'name'),
              const AppDataTableColumn(label: 'Rate', key: 'base_rate', numeric: true),
              const AppDataTableColumn(label: 'Stock Qty', key: 'stock_quantity', numeric: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, List<Map<String, dynamic>> items, void Function([Map<String, dynamic>?]) onAdd, List<AppDataTableColumn> cols) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => onAdd(),
                icon: const Icon(Icons.add),
                label: Text('New $title'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            clipBehavior: Clip.antiAlias,
            child: AppDataTable(
              columns: cols,
              data: items,
              isLoading: _loading,
              onRowTap: (row) => onAdd(row as Map<String, dynamic>),
            ),
          ),
        ),
      ],
    );
  }
}
