import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/models/delivery_model.dart';
import 'package:laundrypro_uae/services/delivery_service.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key, this.deliveryService});

  final DeliveryService? deliveryService;

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  late final DeliveryService _delivery;
  List<DeliveryModel> _items = [];
  bool _loading = true;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _delivery = widget.deliveryService ?? DeliveryService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final filter = _statusFilter == 'all' ? null : _statusFilter;
      _items = await _delivery.list(status: filter);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _updateStatus(DeliveryModel task, String status) async {
    final id = task.id;
    if (id == null) return;
    try {
      await _delivery.update(id, {'status': status});
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('delivery')),
        actions: [IconButton(onPressed: _load, icon: Icon(PhosphorPhosphorIcons.circle()()))],
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
                          Text('Delivery Tasks (${_items.length} active)', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Icon(PhosphorPhosphorIcons.circle()()),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text(context.l10n.t('all'))),
                    ButtonSegment(value: 'pending', label: Text(context.l10n.t('pending_invoices'))),
                    ButtonSegment(value: 'in_transit', label: Text('Transit')),
                    ButtonSegment(value: 'delivered', label: Text(context.l10n.t('status_delivered'))),
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
                    ? Center(child: Text(l10n.t('delivery_empty')))
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final t = _items[i];
                          final status = t.status ?? 'pending';
                          final isDelivered = status == 'delivered';
                          final isInTransit = status == 'in_transit';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDelivered
                                  ? Colors.green.shade100
                                  : (isInTransit ? Colors.blue.shade100 : Colors.amber.shade100),
                              child: Icon(
                                isDelivered
                                    ? PhosphorPhosphorIcons.circle()()
                                    : (isInTransit ? PhosphorIcons.circle() : PhosphorIcons.circle()),
                                color: isDelivered
                                    ? Colors.green.shade900
                                    : (isInTransit ? Colors.blue.shade900 : Colors.amber.shade900),
                              ),
                            ),
                            title: Text('${l10n.t('orders')} #${t.salesOrderId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Address: ${t.deliveryAddress ?? 'Counter Pickup'} · Driver: ${t.driverName ?? 'Unassigned'}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (status == 'pending')
                                  FilledButton.tonal(
                                    onPressed: () => _updateStatus(t, 'in_transit'),
                                    child: const Text('Dispatch'),
                                  )
                                else if (status == 'in_transit')
                                  FilledButton(
                                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                                    onPressed: () => _updateStatus(t, 'delivered'),
                                    child: const Text('Mark Delivered'),
                                  ),
                                PopupMenuButton<String>(
                                  onSelected: (s) => _updateStatus(t, s),
                                  itemBuilder: (ctx) => [
                                    PopupMenuItem(value: 'pending', child: Text(l10n.t('status_pending'))),
                                    PopupMenuItem(value: 'in_transit', child: Text(l10n.t('status_in_transit'))),
                                    PopupMenuItem(value: 'delivered', child: Text(l10n.t('status_delivered'))),
                                    const PopupMenuItem(value: 'failed', child: Text('Failed / Rescheduled')),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
