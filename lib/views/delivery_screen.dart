import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/logger.dart';
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
    } catch (e, stack) {
      AppLogger.error('Failed to load delivery tasks', tag: 'DeliveryScreen', error: e, stackTrace: stack);
    }
    setState(() => _loading = false);
  }

  Future<void> _updateStatus(DeliveryModel task, String status) async {
    final id = task.id;
    try {
      await _delivery.update(id, {'status': status});
      await _load();
    } catch (e, stack) {
      AppLogger.error('Failed to update delivery task status', tag: 'DeliveryScreen', error: e, stackTrace: stack);
    }
  }

  Future<void> _reconcileCod(DeliveryModel task) async {
    try {
      await _delivery.update(task.id, {'cod_collected': 1});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('COD of AED ${task.codAmount.toStringAsFixed(2)} reconciled for Order #${task.salesOrderId}'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
      await _load();
    } catch (e, stack) {
      AppLogger.error('Failed to reconcile COD', tag: 'DeliveryScreen', error: e, stackTrace: stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('delivery')),
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
                          Text('Delivery Tasks (${_items.length} active)', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Icon(Icons.local_shipping_outlined),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'all', label: Text(context.l10n.t('all'))),
                    ButtonSegment(value: 'pending', label: Text(context.l10n.t('pending_invoices'))),
                    const ButtonSegment(value: 'in_transit', label: Text('Transit')),
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
                        itemBuilder: (listCtx, i) {
                          final t = _items[i];
                          final status = t.status;
                          final isDelivered = status == 'delivered';
                          final isInTransit = status == 'in_transit';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDelivered
                                  ? Colors.green.shade100
                                  : (isInTransit ? Colors.blue.shade100 : Colors.amber.shade100),
                              child: Icon(
                                isDelivered
                                    ? Icons.check_circle
                                    : (isInTransit ? Icons.directions_bike : Icons.schedule),
                                color: isDelivered
                                    ? Colors.green.shade900
                                    : (isInTransit ? Colors.blue.shade900 : Colors.amber.shade900),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text('${l10n.t('orders')} #${t.salesOrderId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(t.routeZone, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Address: ${t.deliveryAddress ?? 'Counter Pickup'} · Driver: ${t.driverName ?? 'Unassigned'}'),
                                if (t.codAmount > 0) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: t.codCollected ? Colors.green.shade50 : Colors.amber.shade50,
                                          border: Border.all(color: t.codCollected ? Colors.green : Colors.amber.shade800),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'COD: AED ${t.codAmount.toStringAsFixed(2)} (${t.codCollected ? "COLLECTED" : "DUE ON DELIVERY"})',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: t.codCollected ? Colors.green.shade900 : Colors.amber.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            isThreeLine: t.codAmount > 0,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (t.codAmount > 0 && !t.codCollected)
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.green.shade800,
                                      side: BorderSide(color: Colors.green.shade800),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(Icons.payments_outlined, size: 14),
                                    label: const Text('Reconcile COD'),
                                    onPressed: () => _reconcileCod(t),
                                  ),
                                const SizedBox(width: 8),
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
