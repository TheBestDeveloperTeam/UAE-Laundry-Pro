import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/purchase_service.dart';

class PurchasingScreen extends StatefulWidget {
  const PurchasingScreen({super.key, this.purchaseService});

  final PurchaseService? purchaseService;

  @override
  State<PurchasingScreen> createState() => _PurchasingScreenState();
}

class _PurchasingScreenState extends State<PurchasingScreen> {
  late final PurchaseService _purchases;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _purchases = widget.purchaseService ?? PurchaseService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _purchases.list();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _create() async {
    final l10n = context.l10n;
    final vendorController = TextEditingController();
    final notesController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('po_create')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: vendorController,
              decoration: InputDecoration(labelText: l10n.t('vendor_id')),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: notesController,
              decoration: InputDecoration(labelText: l10n.t('notes')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.t('pos_close'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.t('save'))),
        ],
      ),
    );
    if (ok != true) return;

    final vendorId = int.tryParse(vendorController.text.trim());
    if (vendorId == null) return;

    await _purchases.create({
      'vendor_id': vendorId,
      if (notesController.text.isNotEmpty) 'notes': notesController.text.trim(),
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('purchasing')),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(l10n.t('purchasing_empty')))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final po = _items[i];
                    return ListTile(
                      title: Text(po['po_no']?.toString() ?? ''),
                      subtitle: Text('${l10n.t('vendors')} #${po['vendor_id']} · ${po['status']}'),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(onPressed: _create, child: const Icon(Icons.add)),
    );
  }
}
