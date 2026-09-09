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

  // Search & Filter
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
    final descCtrl = TextEditingController(text: existing?['description']?.toString() ?? '');
    final rateCtrl = TextEditingController(text: existing?['base_rate']?.toString() ?? '10.00');
    final costCtrl = TextEditingController(text: existing?['cost']?.toString() ?? '0.00');
    int? parentId = existing?['parent_id'] as int?;
    bool isGroup = existing?['is_group'] == 1 || existing?['is_group'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isNew ? 'New Service' : 'Edit Service'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Service Name (EN / AR) *'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeCtrl,
                            decoration: const InputDecoration(labelText: 'Service Code (e.g. DRY-01)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: parentId,
                            decoration: const InputDecoration(labelText: 'Parent Service (Hierarchy)'),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('None (Root Service)')),
                              ..._services
                                  .where((s) => s['id'] != existing?['id'])
                                  .map((s) => DropdownMenuItem<int?>(
                                        value: s['id'] as int?,
                                        child: Text(s['name']?.toString() ?? ''),
                                      )),
                            ],
                            onChanged: (val) => setDialogState(() => parentId = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Base Rate (AED) *'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Cost (AED)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description / Instructions'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Is Bundle / Package Group?'),
                      subtitle: const Text('Combines multiple operations into a single package'),
                      value: isGroup,
                      onChanged: (val) => setDialogState(() => isGroup = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final payload = {
                    'name': name,
                    if (codeCtrl.text.trim().isNotEmpty) 'code': codeCtrl.text.trim(),
                    if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
                    'base_rate': double.tryParse(rateCtrl.text.trim()) ?? 0.0,
                    'cost': double.tryParse(costCtrl.text.trim()) ?? 0.0,
                    'parent_id': parentId,
                    'is_group': isGroup ? 1 : 0,
                  };

                  try {
                    if (isNew) {
                      await _catalog.createService(payload);
                    } else {
                      await _catalog.updateService(existing['id'] as int, payload);
                    }
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _load();
                  } catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Failed to save service: $e')),
                    );
                  }
                },
                child: const Text('Save Service'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showProductDialog([Map<String, dynamic>? existing]) {
    final isNew = existing == null;
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final barcodeCtrl = TextEditingController(text: existing?['barcode']?.toString() ?? '');
    final codeCtrl = TextEditingController(text: existing?['code']?.toString() ?? '');
    final descCtrl = TextEditingController(text: existing?['description']?.toString() ?? '');
    final rateCtrl = TextEditingController(text: existing?['base_rate']?.toString() ?? '5.00');
    final costCtrl = TextEditingController(text: existing?['cost']?.toString() ?? '0.00');
    final stockCtrl = TextEditingController(text: existing?['stock_quantity']?.toString() ?? '0');
    final thresholdCtrl = TextEditingController(text: existing?['low_stock_threshold']?.toString() ?? '5');
    int? parentId = existing?['parent_id'] as int?;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isNew ? 'New Product' : 'Edit Product'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Product / Garment Name *'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: barcodeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Barcode / Tag ID',
                              prefixIcon: Icon(Icons.qr_code_2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: codeCtrl,
                            decoration: const InputDecoration(labelText: 'Product Code'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      initialValue: parentId,
                      decoration: const InputDecoration(labelText: 'Parent Category (Hierarchy)'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('None (Root Category)')),
                        ..._products
                            .where((p) => p['id'] != existing?['id'])
                            .map((p) => DropdownMenuItem<int?>(
                                  value: p['id'] as int?,
                                  child: Text(p['name']?.toString() ?? ''),
                                )),
                      ],
                      onChanged: (val) => setDialogState(() => parentId = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Base Rate (AED) *'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Cost Price (AED)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: stockCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Current Stock Quantity'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: thresholdCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Low Stock Alert Threshold'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description / Fabric Care Notes'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final payload = {
                    'name': name,
                    if (barcodeCtrl.text.trim().isNotEmpty) 'barcode': barcodeCtrl.text.trim(),
                    if (codeCtrl.text.trim().isNotEmpty) 'code': codeCtrl.text.trim(),
                    if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
                    'base_rate': double.tryParse(rateCtrl.text.trim()) ?? 0.0,
                    'cost': double.tryParse(costCtrl.text.trim()) ?? 0.0,
                    'stock_quantity': double.tryParse(stockCtrl.text.trim()) ?? 0.0,
                    'low_stock_threshold': double.tryParse(thresholdCtrl.text.trim()) ?? 5.0,
                    'parent_id': parentId,
                  };

                  try {
                    if (isNew) {
                      await _catalog.createProduct(payload);
                    } else {
                      await _catalog.updateProduct(existing['id'] as int, payload);
                    }
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _load();
                  } catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Failed to save product: $e')),
                    );
                  }
                },
                child: const Text('Save Product'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showModifiersDialog(Map<String, dynamic> item, bool isService) {
    final title = '${item['name']} — Modifiers';
    List<Map<String, dynamic>> modifiers = [];
    bool modLoading = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModState) {
          void fetchMods() async {
            try {
              final id = item['id'] as int;
              final list = isService
                  ? await _catalog.listServiceModifiers(id)
                  : await _catalog.listProductModifiers(id);
              setModState(() {
                modifiers = list;
                modLoading = false;
              });
            } catch (_) {
              setModState(() => modLoading = false);
            }
          }

          if (modLoading) {
            fetchMods();
          }

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.tune),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: SizedBox(
              width: 500,
              height: 400,
              child: modLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Expanded(
                          child: modifiers.isEmpty
                              ? const Center(child: Text('No modifiers attached yet'))
                              : ListView.builder(
                                  itemCount: modifiers.length,
                                  itemBuilder: (context, i) {
                                    final m = modifiers[i];
                                    return ListTile(
                                      title: Text(m['name']?.toString() ?? ''),
                                      subtitle: Text('${m['price_type']} — AED ${m['price_value']}'),
                                    );
                                  },
                                ),
                        ),
                        const Divider(),
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Attach Modifier'),
                          onPressed: () async {
                            final nameCtrl = TextEditingController();
                            final valCtrl = TextEditingController(text: '2.00');
                            String type = 'fixed';

                            await showDialog(
                              context: context,
                              builder: (subCtx) => StatefulBuilder(
                                builder: (context, setSubState) => AlertDialog(
                                  title: const Text('Add Modifier (e.g. Express, Fragrance)'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: nameCtrl,
                                        decoration: const InputDecoration(labelText: 'Modifier Name *'),
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        initialValue: type,
                                        decoration: const InputDecoration(labelText: 'Pricing Type'),
                                        items: const [
                                          DropdownMenuItem(value: 'fixed', child: Text('Fixed Surcharge (+AED)')),
                                          DropdownMenuItem(value: 'percentage', child: Text('Percentage (+%)')),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) setSubState(() => type = val);
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: valCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(labelText: 'Price Value'),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(subCtx), child: const Text('Cancel')),
                                    FilledButton(
                                      onPressed: () async {
                                        if (nameCtrl.text.trim().isEmpty) return;
                                        final id = item['id'] as int;
                                        final payload = {
                                          'name': nameCtrl.text.trim(),
                                          'price_type': type,
                                          'price_value': double.tryParse(valCtrl.text.trim()) ?? 0.0,
                                        };
                                        if (isService) {
                                          await _catalog.createServiceModifier(id, payload);
                                        } else {
                                          await _catalog.createProductModifier(id, payload);
                                        }
                                        if (!subCtx.mounted) return;
                                        Navigator.pop(subCtx);
                                        setModState(() => modLoading = true);
                                      },
                                      child: const Text('Add'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ],
          );
        },
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
            Tab(icon: const Icon(Icons.local_laundry_service), text: l10n.t('pos_services')),
            Tab(icon: const Icon(Icons.checkroom), text: l10n.t('catalog_products')),
          ],
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _buildServicesList(),
                _buildProductsList(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tabs.index == 0 ? _showServiceDialog() : _showProductDialog(),
        icon: const Icon(Icons.add),
        label: Text(_tabs.index == 0 ? 'Add Service' : 'Add Product'),
      ),
    );
  }

  Widget _buildServicesList() {
    if (_services.isEmpty) {
      return Center(child: Text(context.l10n.t('catalog_empty')));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _services.length,
      itemBuilder: (context, i) {
        final s = _services[i];
        final isGroup = s['is_group'] == 1 || s['is_group'] == true;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isGroup ? Colors.amber.shade100 : Colors.teal.shade50,
              child: Icon(
                isGroup ? Icons.inventory_2_outlined : Icons.dry_cleaning,
                color: isGroup ? Colors.amber.shade900 : Colors.teal.shade800,
              ),
            ),
            title: Row(
              children: [
                Text(s['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (isGroup) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.amber.shade200, borderRadius: BorderRadius.circular(4)),
                    child: const Text('BUNDLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              'Code: ${s['code'] ?? 'N/A'} • Rate: AED ${s['base_rate']} • Cost: AED ${s['cost']}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Modifiers',
                  icon: const Icon(Icons.tune),
                  onPressed: () => _showModifiersDialog(s, true),
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showServiceDialog(s),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsList() {
    if (_products.isEmpty) {
      return Center(child: Text(context.l10n.t('catalog_empty')));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _products.length,
      itemBuilder: (context, i) {
        final p = _products[i];
        final stock = double.tryParse(p['stock_quantity']?.toString() ?? '0') ?? 0;
        final threshold = double.tryParse(p['low_stock_threshold']?.toString() ?? '0') ?? 0;
        final isLow = stock <= threshold;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isLow ? Colors.red.shade50 : Colors.blue.shade50,
              child: Icon(Icons.checkroom, color: isLow ? Colors.red : Colors.blue),
            ),
            title: Row(
              children: [
                Text(p['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (p['barcode'] != null && p['barcode'].toString().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                    child: Text('BARCODE: ${p['barcode']}', style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              'Rate: AED ${p['base_rate']} • Stock: ${stock.toStringAsFixed(0)} ${isLow ? '(LOW STOCK ALERT)' : ''}',
              style: TextStyle(color: isLow ? Colors.red.shade800 : Colors.grey.shade700, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Modifiers',
                  icon: const Icon(Icons.tune),
                  onPressed: () => _showModifiersDialog(p, false),
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showProductDialog(p),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
