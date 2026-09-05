import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/catalog_service.dart';

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
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final services = await _catalog.listServices();
      final products = await _catalog.listProducts();
      setState(() {
        _services = services;
        _products = products;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addService() async {
    final name = await _promptName(context, context.l10n.t('catalog_add_service'));
    if (name == null || name.isEmpty) return;
    await _catalog.createService({'name': name, 'base_rate': 10});
    await _load();
  }

  Future<void> _addProduct() async {
    final name = await _promptName(context, context.l10n.t('catalog_add_product'));
    if (name == null || name.isEmpty) return;
    await _catalog.createProduct({'name': name, 'base_rate': 5, 'stock_quantity': 0});
    await _load();
  }

  Future<String?> _promptName(BuildContext context, String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.t('pos_close'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(context.l10n.t('save'))),
        ],
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
            Tab(text: l10n.t('pos_services')),
            Tab(text: l10n.t('catalog_products')),
          ],
        ),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _buildList(_services, (s) => '${s['name']} — ${s['base_rate']}'),
                _buildList(_products, (p) => '${p['name']} — stock ${p['stock_quantity']}'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tabs.index == 0 ? _addService() : _addProduct(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, String Function(Map<String, dynamic>) label) {
    if (items.isEmpty) {
      return Center(child: Text(context.l10n.t('catalog_empty')));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) => ListTile(title: Text(label(items[i]))),
    );
  }
}
