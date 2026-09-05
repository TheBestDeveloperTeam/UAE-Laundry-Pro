import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, this.analyticsService});
  final AnalyticsService? analyticsService;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final AnalyticsService _service;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _trends = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = widget.analyticsService ?? AnalyticsService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _summary = await _service.summary();
      final to = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final from = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 30)));
      _trends = await _service.trends(metric: 'sales_total', from: from, to: to);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('analytics')),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.t('dashboard_today_sales'), style: Theme.of(context).textTheme.titleMedium),
                        Text(fmt.format(_summary['sales_total'] ?? 0), style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text('${l10n.t('dashboard_orders')}: ${_summary['order_count'] ?? 0}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l10n.t('analytics_trends'), style: Theme.of(context).textTheme.titleMedium),
                if (_trends.isEmpty) Text(l10n.t('reports_empty')),
                ..._trends.map((p) => ListTile(
                      title: Text(p['snapshot_date']?.toString() ?? ''),
                      trailing: Text(fmt.format(p['metric_value'] ?? 0)),
                    )),
              ],
            ),
    );
  }
}
