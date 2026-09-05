import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/delivery_service.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key, this.deliveryService});

  final DeliveryService? deliveryService;

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  late final DeliveryService _delivery;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _delivery = widget.deliveryService ?? DeliveryService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _delivery.list(status: _statusFilter);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _updateStatus(Map<String, dynamic> task, String status) async {
    final id = int.tryParse(task['id']?.toString() ?? '');
    if (id == null) return;
    await _delivery.update(id, {'status': status});
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('delivery')),
        actions: [
          PopupMenuButton<String?>(
            onSelected: (v) {
              _statusFilter = v;
              _load();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: null, child: Text(l10n.t('all'))),
              PopupMenuItem(value: 'pending', child: Text(l10n.t('status_pending'))),
              PopupMenuItem(value: 'in_transit', child: Text(l10n.t('status_in_transit'))),
              PopupMenuItem(value: 'delivered', child: Text(l10n.t('status_delivered'))),
            ],
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(l10n.t('delivery_empty')))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final t = _items[i];
                    return ListTile(
                      title: Text('${l10n.t('orders')} #${t['sales_order_id']}'),
                      subtitle: Text('${l10n.t('status')}: ${t['status']} · ${t['delivery_address'] ?? ''}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (s) => _updateStatus(t, s),
                        itemBuilder: (ctx) => [
                          PopupMenuItem(value: 'pending', child: Text(l10n.t('status_pending'))),
                          PopupMenuItem(value: 'in_transit', child: Text(l10n.t('status_in_transit'))),
                          PopupMenuItem(value: 'delivered', child: Text(l10n.t('status_delivered'))),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
