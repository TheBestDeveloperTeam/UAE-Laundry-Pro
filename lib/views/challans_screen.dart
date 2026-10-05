import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/document_renderer.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/theme.dart';
import 'package:laundrypro_uae/models/challan_model.dart';
import 'package:laundrypro_uae/services/challan_service.dart';

class ChallansScreen extends StatefulWidget {
  const ChallansScreen({super.key, this.challanService});

  final ChallanService? challanService;

  @override
  State<ChallansScreen> createState() => _ChallansScreenState();
}

class _ChallansScreenState extends State<ChallansScreen> {
  late final ChallanService _challans;
  List<ChallanModel> _items = [];
  bool _loading = true;
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _challans = widget.challanService ?? ChallanService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _challans.list();
    } catch (e, stack) {
      AppLogger.error('Failed to load challans', tag: 'ChallansScreen', error: e, stackTrace: stack);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final l10n = context.l10n;
    String selectedType = 'delivery';
    final notesController = TextEditingController();
    final descController = TextEditingController();
    final qtyController = TextEditingController(text: '1');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.t('challan_create')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    labelText: l10n.t('challan_type'),
                    border: const OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'delivery', child: Text('Customer Delivery')),
                    DropdownMenuItem(value: 'transfer', child: Text('Inter-Branch Transfer')),
                    DropdownMenuItem(value: 'supplier', child: Text('Vendor / Supplier Return')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: l10n.t('description'),
                    hintText: 'e.g. Clean Linen Bundles',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyController,
                  decoration: InputDecoration(
                    labelText: l10n.t('quantity'),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: l10n.t('notes'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.t('pos_close'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.t('save')),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    setState(() => _loading = true);
    try {
      await _challans.create({
        'challan_type': selectedType,
        if (notesController.text.isNotEmpty) 'notes': notesController.text.trim(),
        'lines': [
          {
            'description': descController.text.trim().isEmpty ? 'Laundry Batch' : descController.text.trim(),
            'quantity': double.tryParse(qtyController.text) ?? 1,
          },
        ],
      });
    } catch (e, stack) {
      AppLogger.error('Failed to create challan', tag: 'ChallansScreen', error: e, stackTrace: stack);
    }
    await _load();
  }

  void _preview(ChallanModel item) {
    final thermal = DocumentRenderer.toThermal(item);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.receipt, color: AppTheme.primaryNavy),
            const SizedBox(width: 8),
            Text(item.challanNo),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SingleChildScrollView(
            child: Text(
              thermal,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.t('pos_close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final filtered = _activeFilter == 'all'
        ? _items
        : _items.where((c) => c.challanType.toLowerCase() == _activeFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('challans')),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.t('challan_create')),
        onPressed: _create,
      ),
      body: Column(
        children: [
          // Filter Chips Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('All (${_items.length})'),
                  selected: _activeFilter == 'all',
                  onSelected: (val) {
                    if (val) setState(() => _activeFilter = 'all');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Delivery'),
                  selected: _activeFilter == 'delivery',
                  onSelected: (val) {
                    if (val) setState(() => _activeFilter = 'delivery');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Transfer'),
                  selected: _activeFilter == 'transfer',
                  onSelected: (val) {
                    if (val) setState(() => _activeFilter = 'transfer');
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Challans List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.t('challans_empty'),
                          style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final c = filtered[i];
                            final isDelivery = c.challanType == 'delivery';

                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: isDelivery
                                      ? AppTheme.accentTeal.withValues(alpha: 0.15)
                                      : AppTheme.primaryNavy.withValues(alpha: 0.12),
                                  child: Icon(
                                    isDelivery ? Icons.local_shipping : Icons.sync_alt,
                                    color: isDelivery ? AppTheme.accentTeal : AppTheme.primaryNavy,
                                  ),
                                ),
                                title: Text(c.challanNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: Text(
                                  'Type: ${c.challanType.toUpperCase()} • Items: ${c.lines.length}\nStatus: ${c.status.toUpperCase()}',
                                  style: const TextStyle(color: AppTheme.secondaryGrey),
                                ),
                                isThreeLine: true,
                                trailing: const Icon(Icons.receipt_long, color: AppTheme.primaryNavy),
                                onTap: () => _preview(c),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
