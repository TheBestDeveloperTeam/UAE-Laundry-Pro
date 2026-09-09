import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
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

  final Map<String, List<Map<String, dynamic>>> _boardData = {
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
      final newBoard = <String, List<Map<String, dynamic>>>{
        for (final stage in _kanbanStages) stage: [],
      };

      for (final order in allOrders) {
        final status = order['status']?.toString() ?? 'received';
        if (newBoard.containsKey(status)) {
          newBoard[status]!.add(order);
        }
      }

      setState(() {
        _boardData.clear();
        _boardData.addAll(newBoard);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _changeStatus(Map<String, dynamic> order, String newStatus, {String? notes}) async {
    final id = int.tryParse(order['id']?.toString() ?? '');
    if (id == null) return;

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

  Future<void> _showStatusDialog(Map<String, dynamic> order) async {
    final current = order['status']?.toString() ?? '';
    final notesController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Stage Transition — ${order['order_no']}'),
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
                backgroundColor: Colors.amber.shade100,
                avatar: const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber),
                label: const Text('Rework Required'),
                onPressed: () => Navigator.pop(ctx, 'rework_required'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'QC / Audit Notes (Optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
        return Colors.blueGrey;
      case 'sorting':
        return Colors.indigo;
      case 'processing':
        return Colors.blue;
      case 'quality_check':
        return Colors.purple;
      case 'packed':
        return Colors.teal;
      case 'ready_for_collection':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('production')),
        actions: [
          IconButton(
            icon: Icon(_isKanbanMode ? Icons.view_list : Icons.view_kanban),
            tooltip: _isKanbanMode ? 'List View' : 'Kanban Board',
            onPressed: () => setState(() => _isKanbanMode = !_isKanbanMode),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllStages,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.qr_code_scanner),
                      hintText: 'Scan order barcode or search order number...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => _searchFilter = val.trim().toLowerCase()),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _isKanbanMode
                    ? _buildKanbanBoard()
                    : _buildTabularView(),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanBoard() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _kanbanStages.map((stage) {
          final orders = (_boardData[stage] ?? []).where((o) {
            if (_searchFilter.isEmpty) return true;
            final no = (o['order_no']?.toString() ?? '').toLowerCase();
            return no.contains(_searchFilter);
          }).toList();

          final stageColor = _getStageColor(stage);

          return DragTarget<Map<String, dynamic>>(
            onWillAcceptWithDetails: (details) => details.data['status'] != stage,
            onAcceptWithDetails: (details) => _changeStatus(details.data, stage),
            builder: (context, candidateData, rejectedData) {
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: candidateData.isNotEmpty
                      ? stageColor.withValues(alpha: 0.15)
                      : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: candidateData.isNotEmpty ? stageColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: stageColor.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        border: Border(bottom: BorderSide(color: stageColor.withValues(alpha: 0.3))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            stage.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: stageColor),
                          ),
                          Badge(
                            label: Text('${orders.length}'),
                            backgroundColor: stageColor,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: orders.isEmpty
                          ? Center(
                              child: Text(
                                'No orders',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                final o = orders[index];
                                return Draggable<Map<String, dynamic>>(
                                  data: o,
                                  feedback: Material(
                                    elevation: 6,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 260,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: stageColor),
                                      ),
                                      child: Text(o['order_no']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildOrderCard(Map<String, dynamic> o, String stage, Color stageColor) {
    final next = _nextStatus[stage];

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(o['order_no']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showStatusDialog(o),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Customer: ${o['customer_name'] ?? o['customer']?['name'] ?? 'Walk-In'}',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
            Text(
              'Promised: ${o['promised_date'] ?? 'Standard'}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AED ${o['grand_total'] ?? '0.00'}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                if (next != null)
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _changeStatus(o, next),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(next.replaceAll('_', ' '), style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 14),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabularView() {
    final all = <Map<String, dynamic>>[];
    for (final list in _boardData.values) {
      all.addAll(list);
    }
    final filtered = all.where((o) {
      if (_searchFilter.isEmpty) return true;
      return (o['order_no']?.toString() ?? '').toLowerCase().contains(_searchFilter);
    }).toList();

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final o = filtered[i];
        final current = o['status']?.toString() ?? '';
        final next = _nextStatus[current];

        return ListTile(
          title: Text(o['order_no']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Stage: ${current.toUpperCase()} · Total: AED ${o['grand_total'] ?? '0.00'}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (next != null)
                FilledButton.tonal(
                  onPressed: () => _changeStatus(o, next),
                  child: Text('Move to ${next.replaceAll('_', ' ').toUpperCase()}'),
                ),
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () => _showStatusDialog(o),
              ),
            ],
          ),
        );
      },
    );
  }
}
