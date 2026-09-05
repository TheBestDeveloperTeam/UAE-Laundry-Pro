import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/sales_service.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key, this.salesService});

  final SalesService? salesService;

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> with SingleTickerProviderStateMixin {
  late final SalesService _sales;
  late final TabController _tabs;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  static const _statuses = [
    'received',
    'sorting',
    'processing',
    'quality_check',
    'packed',
    'ready_for_collection',
    'out_for_delivery',
    'delivered',
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
    _tabs = TabController(length: _statuses.length, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _sales.list(status: _statuses[_tabs.index]);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _advanceStatus(Map<String, dynamic> order) async {
    final current = order['status']?.toString() ?? '';
    final next = _nextStatus[current];
    if (next == null) return;
    final id = int.tryParse(order['id']?.toString() ?? '');
    if (id == null) return;
    await _sales.updateStatus(id, next);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('production')),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: _statuses.map((s) => Tab(text: l10n.t('status_$s'))).toList(),
        ),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(l10n.t('production_empty')))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final o = _items[i];
                    final current = o['status']?.toString() ?? '';
                    final canAdvance = _nextStatus.containsKey(current);
                    return ListTile(
                      title: Text(o['order_no']?.toString() ?? ''),
                      subtitle: Text('${l10n.t('status')}: ${o['status']} · ${o['grand_total']}'),
                      trailing: canAdvance
                          ? IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              tooltip: l10n.t('update_status'),
                              onPressed: () => _advanceStatus(o),
                            )
                          : null,
                    );
                  },
                ),
    );
  }
}
