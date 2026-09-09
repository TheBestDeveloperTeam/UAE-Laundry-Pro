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
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _purchases = widget.purchaseService ?? PurchaseService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final filter = _statusFilter == 'all' ? null : _statusFilter;
      _items = await _purchases.list(status: filter);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _create() async {
    final l10n = context.l10n;
    final vendorController = TextEditingController(text: '1');
    final notesController = TextEditingController();
    final amountController = TextEditingController(text: '0.00');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('po_create')),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: vendorController,
                decoration: InputDecoration(labelText: l10n.t('vendor_id'), border: const OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Estimated Total (AED)', prefixText: 'AED ', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: InputDecoration(labelText: l10n.t('notes'), border: const OutlineInputBorder()),
              ),
            ],
          ),
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
      'total_amount': double.tryParse(amountController.text.trim()) ?? 0.0,
      if (notesController.text.isNotEmpty) 'notes': notesController.text.trim(),
    });
    await _load();
  }

  Future<void> _receiveGoods(Map<String, dynamic> po) async {
    final id = int.tryParse(po['id']?.toString() ?? '');
    if (id == null) return;

    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Receive Goods (GRN) — ${po['po_no']}'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Confirm goods receipt from Vendor #${po['vendor_id']}?'),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Receiving Notes / Bill of Lading',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.icon(
            icon: const Icon(Icons.inventory_2),
            onPressed: () => Navigator.pop(ctx, true),
            label: const Text('Confirm GRN'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _purchases.receive(id, {
          'notes': notesController.text.trim(),
          'received_at': DateTime.now().toIso8601String(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('GRN confirmed for ${po['po_no']}! Stock updated.')),
          );
        }
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to receive goods: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('purchasing')),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Purchase Orders (${_items.length} records)', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Icon(Icons.shopping_bag_outlined),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('All')),
                    ButtonSegment(value: 'pending', label: Text('Pending')),
                    ButtonSegment(value: 'received', label: Text('Received')),
                  ],
                  selected: {_statusFilter},
                  onSelectionChanged: (set) {
                    setState(() => _statusFilter = set.first);
                    _load();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(child: Text(l10n.t('purchasing_empty')))
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final po = _items[i];
                          final status = po['status']?.toString() ?? 'pending';
                          final isReceived = status == 'received';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isReceived ? Colors.green.shade100 : Colors.blue.shade100,
                              child: Icon(
                                isReceived ? Icons.inventory_2 : Icons.receipt_long,
                                color: isReceived ? Colors.green.shade900 : Colors.blue.shade900,
                              ),
                            ),
                            title: Text(po['po_no']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${l10n.t('vendors')} #${po['vendor_id']} · Status: ${status.toUpperCase()}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isReceived)
                                  FilledButton.tonalIcon(
                                    icon: const Icon(Icons.download, size: 16),
                                    label: const Text('Receive GRN'),
                                    onPressed: () => _receiveGoods(po),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _create, child: const Icon(Icons.add)),
    );
  }
}
