import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/models/order_model.dart';
import 'package:laundrypro_uae/services/sales_service.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key, this.salesService});

  final SalesService? salesService;

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  late final SalesService _sales;
  bool _loading = true;
  bool _isKanbanMode = true;
  String _searchFilter = '';

  final Map<String, List<OrderModel>> _boardData = {
    'received': [],
    'sorting': [],
    'processing': [],
    'quality_check': [],
    'packed': [],
    'ready_for_collection': [],
  };

  static const _kanbanStages = [
    'received',
    'sorting',
    'processing',
    'quality_check',
    'packed',
    'ready_for_collection',
  ];

  static const _nextStatus = <String, String>{
    'received': 'sorting',
    'sorting': 'processing',
    'processing': 'quality_check',
    'quality_check': 'packed',
    'packed': 'ready_for_collection',
    'ready_for_collection': 'out_for_delivery',
    'out_for_delivery': 'delivered',
    'delivered': 'closed',
  };

  @override
  void initState() {
    super.initState();
    _sales = widget.salesService ?? SalesService();
    _loadAllStages();
  }

  Future<void> _loadAllStages() async {
    setState(() => _loading = true);
    try {
      final allOrders = await _sales.list(limit: 200);
      final newBoard = <String, List<OrderModel>>{
        for (final stage in _kanbanStages) stage: [],
      };

      for (final order in allOrders) {
        final status = order.status;
        if (newBoard.containsKey(status)) {
          newBoard[status]!.add(order);
        }
      }

      if (mounted) {
        setState(() {
          _boardData.clear();
          _boardData.addAll(newBoard);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeStatus(OrderModel order, String newStatus, {String? notes}) async {
    final id = order.id;
    try {
      await _sales.updateStatus(id, newStatus);
      await _loadAllStages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update stage: $e')),
        );
      }
    }
  }

  Future<void> _showStatusDialog(OrderModel order) async {
    final l10n = context.l10n;
    final current = order.status;
    final notesController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTokens.surfacePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusLarge)),
        title: Text('Stage Transition - ${order.orderNo}', style: AppTokens.sectionHeading),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Stage: ${current.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Select Next Stage:'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kanbanStages.where((s) => s != current).map((s) {
                  return ActionChip(
                    label: Text(s.toUpperCase()),
                    onPressed: () => Navigator.pop(ctx, s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              ActionChip(
                backgroundColor: AppTokens.statusBgCancelled,
                avatar: const Icon(Icons.warning_amber_rounded, size: 16, color: AppTokens.statusCancelled),
                label: const Text('Rework Required', style: TextStyle(color: AppTokens.statusCancelled)),
                onPressed: () => Navigator.pop(ctx, 'rework_required'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium)),
                  labelText: l10n.t('production_qc_notes'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.t('cancel'))),
        ],
      ),
    );

    if (result != null) {
      await _changeStatus(order, result, notes: notesController.text.trim());
    }
  }

  Color _getStageColor(String stage) {
    switch (stage) {
      case 'received':
        return AppTokens.statusReceived;
      case 'sorting':
      case 'processing':
        return AppTokens.statusWashing;
      case 'quality_check':
        return AppTokens.statusFinishing;
      case 'packed':
      case 'ready_for_collection':
        return AppTokens.statusReady;
      default:
        return AppTokens.textSecondary;
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
                    Text(l10n.t('production'), style: AppTokens.pageHeading),
                    const SizedBox(height: 2),
                    const Text(
                      'Live plant floor workflow & machine queue',
                      style: TextStyle(fontSize: 13, color: AppTokens.textSecondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTokens.surfacePrimary,
                        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                        border: Border.all(color: AppTokens.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(_isKanbanMode ? Icons.view_kanban_rounded : Icons.view_list_rounded, color: AppTokens.brandTeal),
                            tooltip: _isKanbanMode ? 'Kanban View' : 'Table View',
                            onPressed: () => setState(() => _isKanbanMode = !_isKanbanMode),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: AppTokens.textSecondary),
                            onPressed: _loadAllStages,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space16),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16, vertical: 8),
              decoration: AppTokens.cardDecoration,
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.qr_code_scanner, color: AppTokens.brandTeal),
                  hintText: l10n.t('scan_or_search_orders_hint'),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (val) => setState(() => _searchFilter = val.trim().toLowerCase()),
              ),
            ),
            const SizedBox(height: AppTokens.space16),

            // Board Viewport
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _isKanbanMode
                      ? _buildKanbanBoard()
                      : _buildTabularView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanBoard() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _kanbanStages.map((stage) {
          final orders = (_boardData[stage] ?? []).where((o) {
            if (_searchFilter.isEmpty) return true;
            final no = o.orderNo.toLowerCase();
            return no.contains(_searchFilter);
          }).toList();

          final stageColor = _getStageColor(stage);

          return DragTarget<OrderModel>(
            onWillAcceptWithDetails: (details) => details.data.status != stage,
            onAcceptWithDetails: (details) => _changeStatus(details.data, stage),
            builder: (context, candidateData, rejectedData) {
              return Container(
                width: 280,
                margin: const EdgeInsetsDirectional.only(end: 12),
                decoration: BoxDecoration(
                  color: candidateData.isNotEmpty ? stageColor.withValues(alpha: 0.1) : AppTokens.surfacePrimary,
                  borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                  border: Border.all(color: candidateData.isNotEmpty ? stageColor : AppTokens.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: stageColor.withValues(alpha: 0.08),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLarge)),
                        border: Border(bottom: BorderSide(color: stageColor.withValues(alpha: 0.2))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            stage.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: stageColor),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: stageColor,
                              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                            ),
                            child: Text(
                              '${orders.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: orders.isEmpty
                          ? const Center(
                              child: Text(
                                'No orders',
                                style: TextStyle(color: AppTokens.textMuted, fontSize: 12),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(AppTokens.space8),
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                final o = orders[index];
                                return Draggable<OrderModel>(
                                  data: o,
                                  feedback: Material(
                                    elevation: 6,
                                    borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                                    child: Container(
                                      width: 260,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTokens.surfacePrimary,
                                        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                                        border: Border.all(color: stageColor),
                                      ),
                                      child: Text(o.orderNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.4,
                                    child: _buildOrderCard(o, stage, stageColor),
                                  ),
                                  child: _buildOrderCard(o, stage, stageColor),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel o, String stage, Color stageColor) {
    final next = _nextStatus[stage];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppTokens.space12),
      decoration: BoxDecoration(
        color: AppTokens.surfacePrimary,
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        border: Border.all(color: AppTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(o.orderNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTokens.textPrimary)),
              IconButton(
                icon: const Icon(Icons.more_horiz, size: 18, color: AppTokens.textMuted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showStatusDialog(o),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Customer: ${o.customerName ?? 'Walk-In'}',
            style: const TextStyle(fontSize: 12, color: AppTokens.textSecondary),
          ),
          Text(
            'Promised: ${o.promisedDate ?? 'Standard'}',
            style: const TextStyle(fontSize: 11, color: AppTokens.textMuted),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AED ${o.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTokens.textPrimary),
              ),
              if (next != null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.brandTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSmall)),
                  ),
                  onPressed: () => _changeStatus(o, next),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(next.replaceAll('_', ' '), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 14),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabularView() {
    final all = <OrderModel>[];
    for (final list in _boardData.values) {
      all.addAll(list);
    }
    final filtered = all.where((o) {
      if (_searchFilter.isEmpty) return true;
      return o.orderNo.toLowerCase().contains(_searchFilter);
    }).toList();

    return Container(
      decoration: AppTokens.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppTokens.borderSubtle),
        itemBuilder: (context, i) {
          final o = filtered[i];
          final current = o.status;
          final next = _nextStatus[current];

          return ListTile(
            title: Text(o.orderNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('Stage: ${current.toUpperCase()} - Total: AED ${o.grandTotal.toStringAsFixed(2)}', style: const TextStyle(color: AppTokens.textSecondary)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (next != null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTokens.brandTeal, foregroundColor: Colors.white, elevation: 0),
                    onPressed: () => _changeStatus(o, next),
                    child: Text('Move to ${next.replaceAll('_', ' ').toUpperCase()}'),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.tune, color: AppTokens.textSecondary),
                  onPressed: () => _showStatusDialog(o),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
