import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/services/reports_service.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.reportsService});

  final ReportsService? reportsService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ReportsService _reports;
  Map<String, dynamic> _today = {};
  Map<String, dynamic> _period = {};
  Map<String, dynamic> _inventory = {};
  bool _loading = true;
  String? _error;

  final _currency = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _reports = widget.reportsService ?? ReportsService();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _reports.todaySalesSummary(),
        _reports.salesSummary(),
        _reports.inventoryValuation(),
      ]);
      _today = results[0];
      _period = results[1];
      _inventory = results[2];
    } catch (_) {
      _error = 'load_failed';
    }
    setState(() => _loading = false);
  }

  String _money(dynamic v) => _currency.format(double.tryParse(v?.toString() ?? '0') ?? 0);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isAdmin = user?.role == 'administrator';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('dashboard')),
        actions: [
          IconButton(onPressed: _loadSummary, icon: const Icon(Icons.refresh)),
          if (isAdmin)
            IconButton(
              tooltip: l10n.t('settings'),
              onPressed: () => context.go('/settings'),
              icon: const Icon(Icons.settings_outlined),
            ),
          IconButton(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
            tooltip: l10n.t('logout'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('${l10n.t('welcome')}, ${user?.fullName ?? ''}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Chip(label: Text(auth.apiHealthy ? l10n.t('status_connected') : l10n.t('status_offline'))),
            if (_error != null) ...[
              const SizedBox(height: 12),
              MaterialBanner(
                content: Text(l10n.t('api_unavailable')),
                actions: [
                  TextButton(onPressed: _loadSummary, child: Text(l10n.t('retry'))),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Text(l10n.t('dashboard_today'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _kpi(l10n.t('dashboard_today_sales'), _money(_today['grand_total']), Icons.payments, () => context.go('/pos')),
                  _kpi(l10n.t('dashboard_outstanding'), _money(_today['balance_due']), Icons.receipt_long, () => context.go('/pending')),
                  _kpi(l10n.t('orders'), '${_today['order_count'] ?? 0}', Icons.shopping_bag, () => context.go('/production')),
                  _kpi(l10n.t('dashboard_low_stock'), '${_inventory['product_count'] ?? 0}', Icons.inventory_2, () => context.go('/catalog')),
                ],
              ),
            const SizedBox(height: 24),
            Text(l10n.t('reports_sales'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (!_loading)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _kpi(l10n.t('pos_total'), _money(_period['grand_total']), Icons.bar_chart, () => context.go('/reports')),
                  _kpi(l10n.t('pos_paid'), _money(_period['amount_paid']), Icons.account_balance, () => context.go('/reports')),
                  _kpi(l10n.t('balance'), _money(_period['balance_due']), Icons.warning_amber, () => context.go('/pending')),
                  _kpi(l10n.t('notifications'), '', Icons.notifications, () => context.go('/notifications')),
                ],
              ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              children: [
                FilledButton(onPressed: () => context.go('/pos'), child: Text(l10n.t('pos'))),
                OutlinedButton(onPressed: () => context.go('/pending'), child: Text(l10n.t('pending_invoices'))),
                if (isAdmin) OutlinedButton(onPressed: () => context.go('/catalog'), child: Text(l10n.t('catalog'))),
                if (isAdmin) OutlinedButton(onPressed: () => context.go('/business'), child: Text(l10n.t('business_profile'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpi(String label, String value, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 180,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20),
                const SizedBox(height: 8),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
