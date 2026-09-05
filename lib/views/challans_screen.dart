import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/document_renderer.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/challan_service.dart';

class ChallansScreen extends StatefulWidget {
  const ChallansScreen({super.key, this.challanService});

  final ChallanService? challanService;

  @override
  State<ChallansScreen> createState() => _ChallansScreenState();
}

class _ChallansScreenState extends State<ChallansScreen> {
  late final ChallanService _challans;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

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
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _create() async {
    final l10n = context.l10n;
    final typeController = TextEditingController(text: 'delivery');
    final notesController = TextEditingController();
    final descController = TextEditingController();
    final qtyController = TextEditingController(text: '1');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('challan_create')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: typeController,
                decoration: InputDecoration(labelText: l10n.t('challan_type')),
              ),
              TextField(
                controller: descController,
                decoration: InputDecoration(labelText: l10n.t('description')),
              ),
              TextField(
                controller: qtyController,
                decoration: InputDecoration(labelText: l10n.t('quantity')),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: notesController,
                decoration: InputDecoration(labelText: l10n.t('notes')),
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

    await _challans.create({
      'challan_type': typeController.text.trim(),
      if (notesController.text.isNotEmpty) 'notes': notesController.text.trim(),
      'lines': [
        {
          'description': descController.text.trim().isEmpty ? 'Item' : descController.text.trim(),
          'quantity': double.tryParse(qtyController.text) ?? 1,
        },
      ],
    });
    await _load();
  }

  void _preview(Map<String, dynamic> item) {
    final model = ChallanModel.fromMap(item);
    final thermal = DocumentRenderer.toThermal(model);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item['challan_no']?.toString() ?? ''),
        content: SingleChildScrollView(child: Text(thermal)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.t('pos_close'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('challans')),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(l10n.t('challans_empty')))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final c = _items[i];
                    return ListTile(
                      title: Text(c['challan_no']?.toString() ?? ''),
                      subtitle: Text('${c['challan_type']} · ${c['status']}'),
                      onTap: () => _preview(c),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(onPressed: _create, child: const Icon(Icons.add)),
    );
  }
}
