import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/models/delivery_model.dart';
import 'package:laundrypro_uae/services/delivery_service.dart';
import 'package:laundrypro_uae/widgets/status_badge.dart';

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
    if (mounted) setState(() => _loading = false);
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
            backgroundColor: AppTokens.statusReady,
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
      backgroundColor: AppTokens.canvas,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space24, vertical: AppTokens.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.t('delivery'), style: AppTokens.pageHeading),
                    const SizedBox(height: 2),
                    Text(
                      'Dispatch management, driver route manifests and COD reconciliation',
                      style: AppTokens.caption.copyWith(color: AppTokens.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded, color: AppTokens.textSecondary),
                  tooltip: l10n.t('refresh'),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space16),

            // Metrics / Control Bar
            Container(
              padding: const EdgeInsets.all(AppTokens.space12),
              decoration: BoxDecoration(
                color: AppTokens.surfacePrimary,
                borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                border: Border.all(color: AppTokens.borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16, vertical: AppTokens.space10),
                      decoration: BoxDecoration(
                        color: AppTokens.surfaceSubtle,
                        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                        border: Border.all(color: AppTokens.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Delivery Tasks (${_items.length} active)',
                              style: AppTokens.bodyStrong,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.local_shipping_outlined, color: AppTokens.brandTeal),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.space12),
                  Flexible(
                    child: SegmentedButton<String>(
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space16),

            // Content Body
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTokens.brandTeal))
                  : _items.isEmpty
                      ? Center(
                          child: Text(
                            l10n.t('delivery_empty'),
                            style: AppTokens.bodyRegular.copyWith(color: AppTokens.textMuted),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppTokens.space8),
                          itemBuilder: (listCtx, i) {
                            final t = _items[i];
                            final status = t.status;
                            final isDelivered = status == 'delivered';
                            final isInTransit = status == 'in_transit';

                            return Container(
                              decoration: AppTokens.cardDecoration,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: AppTokens.space16, vertical: AppTokens.space8),
                                leading: CircleAvatar(
                                  backgroundColor: isDelivered
                                      ? AppTokens.statusBgReady
                                      : (isInTransit ? AppTokens.statusBgWashing : AppTokens.statusBgFinishing),
                                  child: Icon(
                                    isDelivered
                                        ? Icons.check_circle
                                        : (isInTransit ? Icons.directions_bike : Icons.schedule),
                                    color: isDelivered
                                        ? AppTokens.statusReady
                                        : (isInTransit ? AppTokens.statusWashing : AppTokens.statusFinishing),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${l10n.t('orders')} #${t.salesOrderId}',
                                        style: AppTokens.bodyStrong,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: AppTokens.space8),
                                    StatusBadge(
                                      label: t.routeZone,
                                      stage: OrderStage.received,
                                      compact: true,
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: AppTokens.space4),
                                    Text(
                                      'Address: ${t.deliveryAddress ?? 'Counter Pickup'} · Driver: ${t.driverName ?? 'Unassigned'}',
                                      style: AppTokens.caption.copyWith(color: AppTokens.textSecondary),
                                    ),
                                    if (t.codAmount > 0) ...[
                                      const SizedBox(height: AppTokens.space6),
                                      Row(
                                        children: [
                                          StatusBadge(
                                            label: 'COD: AED ${t.codAmount.toStringAsFixed(2)} (${t.codCollected ? "COLLECTED" : "DUE ON DELIVERY"})',
                                            stage: t.codCollected ? OrderStage.ready : OrderStage.finishing,
                                            compact: true,
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
                                          foregroundColor: AppTokens.statusReady,
                                          side: const BorderSide(color: AppTokens.statusReady),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        icon: const Icon(Icons.payments_outlined, size: 14),
                                        label: Text(l10n.t('reconcile_cod')),
                                        onPressed: () => _reconcileCod(t),
                                      ),
                                    const SizedBox(width: AppTokens.space8),
                                    if (status == 'pending')
                                      FilledButton.tonal(
                                        onPressed: () => _updateStatus(t, 'in_transit'),
                                        child: Text(l10n.t('dispatch_action')),
                                      )
                                    else if (status == 'in_transit')
                                      FilledButton(
                                        style: FilledButton.styleFrom(backgroundColor: AppTokens.statusReady),
                                        onPressed: () => _updateStatus(t, 'delivered'),
                                        child: Text(l10n.t('mark_delivered')),
                                      ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: AppTokens.textSecondary),
                                      onSelected: (s) => _updateStatus(t, s),
                                      itemBuilder: (ctx) => [
                                        PopupMenuItem(value: 'pending', child: Text(l10n.t('status_pending'))),
                                        PopupMenuItem(value: 'in_transit', child: Text(l10n.t('status_in_transit'))),
                                        PopupMenuItem(value: 'delivered', child: Text(l10n.t('status_delivered'))),
                                        PopupMenuItem(value: 'failed', child: Text(l10n.t('status_failed_rescheduled'))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
