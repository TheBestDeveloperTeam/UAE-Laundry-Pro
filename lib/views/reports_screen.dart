import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/reports_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.reportsService});

  final ReportsService? reportsService;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late final ReportsService _reports;
  late final TabController _tabs;
  bool _loading = false;
  String? _error;
  late DateTime _from;
  late DateTime _to;
  final _currency = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);

  final _cache = <int, Map<String, dynamic>>{};

  @override
  void initState() {
    super.initState();
    _reports = widget.reportsService ?? ReportsService();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = now;
    _tabs = TabController(length: 7, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) _loadTab(force: false);
    });
    _loadTab(force: true);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) => d.toIso8601String().split('T').first;

  Future<void> _loadTab({required bool force}) async {
    final idx = _tabs.index;
    if (!force && _cache.containsKey(idx)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final from = _fmtDate(_from);
      final to = _fmtDate(_to);
      Map<String, dynamic> data;
      switch (idx) {
        case 0:
          data = await _reports.salesSummary(from: from, to: to);
        case 1:
          data = await _reports.expensesSummary(from: from, to: to);
        case 2:
          data = await _reports.payrollSummary(from: from, to: to);
        case 3:
          data = await _reports.inventoryValuation();
        case 4:
          data = await _reports.productionThroughput(from: from, to: to);
        case 5:
          data = await _reports.purchasingReport(from: from, to: to);
        default:
          data = await _reports.deliveryReport(from: from, to: to);
      }
      _cache[idx] = data;
    } catch (_) {
      _error = 'load_failed';
    }
    setState(() => _loading = false);
  }

  Future<void> _applyDates() async {
    _cache.clear();
    await _loadTab(force: true);
  }

  Widget _buildSummary(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return Center(child: Text(context.l10n.t('reports_empty')));
    }

    final flat = <String, dynamic>{};
    void flatten(String prefix, dynamic value) {
      if (value is Map) {
        for (final e in value.entries) {
          flatten(prefix.isEmpty ? e.key : '$prefix.${e.key}', e.value);
        }
      } else {
        flat[prefix] = value;
      }
    }
    flatten('', data);

    if (flat.isEmpty) {
      return Center(child: Text(context.l10n.t('reports_empty')));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: flat.entries.map((e) {
        final v = e.value;
        final display = v is num || double.tryParse(v.toString()) != null
            ? _currency.format(double.tryParse(v.toString()) ?? 0)
            : v.toString();
        return Card(
          child: ListTile(
            title: Text(e.key.replaceAll('_', ' ')),
            trailing: Text(display, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = _cache[_tabs.index] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('reports')),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.t('reports_sales')),
            Tab(text: l10n.t('reports_expenses')),
            Tab(text: l10n.t('reports_payroll')),
            Tab(text: l10n.t('reports_inventory')),
            Tab(text: l10n.t('reports_production')),
            Tab(text: l10n.t('reports_purchasing')),
            Tab(text: l10n.t('reports_delivery')),
          ],
        ),
        actions: [
          IconButton(onPressed: () => _loadTab(force: true), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(context: context, initialDate: _from, firstDate: DateTime(2020), lastDate: DateTime(2100));
                      if (picked != null) {
                        setState(() => _from = picked);
                        await _applyDates();
                      }
                    },
                    child: Text('${l10n.t('reports_from')}: ${_fmtDate(_from)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(context: context, initialDate: _to, firstDate: DateTime(2020), lastDate: DateTime(2100));
                      if (picked != null) {
                        setState(() => _to = picked);
                        await _applyDates();
                      }
                    },
                    child: Text('${l10n.t('reports_to')}: ${_fmtDate(_to)}'),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            MaterialBanner(
              content: Text(l10n.t('reports_error')),
              actions: [TextButton(onPressed: () => _loadTab(force: true), child: Text(l10n.t('retry')))],
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildSummary(data),
          ),
        ],
      ),
    );
  }
}
