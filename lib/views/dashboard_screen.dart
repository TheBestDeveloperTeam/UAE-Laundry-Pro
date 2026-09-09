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
          padding: const EdgeInsets.all(28),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.t('welcome')}, ${user?.fullName ?? ''}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'LaundryPro UAE Cloud & Terminal Node',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: auth.apiHealthy ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: auth.apiHealthy ? Colors.green.shade300 : Colors.orange.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: auth.apiHealthy ? Colors.green.shade600 : Colors.orange.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        auth.apiHealthy ? l10n.t('status_connected') : l10n.t('status_offline'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: auth.apiHealthy ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              MaterialBanner(
                content: Text(l10n.t('api_unavailable')),
                actions: [
                  TextButton(onPressed: _loadSummary, child: Text(l10n.t('retry'))),
                ],
              ),
            ],
            const SizedBox(height: 28),
            Text(
              l10n.t('dashboard_today'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )

            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _kpi(
                    l10n.t('dashboard_today_sales'),
                    _money(_today['grand_total']),
                    Icons.payments_rounded,
                    const Color(0xFF0D6E6E),
                    () => context.go('/pos'),
                  ),
                  _kpi(
                    l10n.t('dashboard_outstanding'),
                    _money(_today['balance_due']),
                    Icons.receipt_long_rounded,
                    Colors.orange.shade800,
                    () => context.go('/pending'),
                  ),
                  _kpi(
                    l10n.t('orders'),
                    '${_today['order_count'] ?? 0}',
                    Icons.shopping_bag_rounded,
                    Colors.blue.shade700,
                    () => context.go('/production'),
                  ),
                  _kpi(
                    l10n.t('dashboard_low_stock'),
                    '${_inventory['product_count'] ?? 0}',
                    Icons.inventory_2_rounded,
                    Colors.purple.shade700,
                    () => context.go('/catalog'),
                  ),
                ],
              ),
            const SizedBox(height: 28),
            Text(
              l10n.t('reports_sales'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (!_loading)
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _kpi(
                    l10n.t('pos_total'),
                    _money(_period['grand_total']),
                    Icons.bar_chart_rounded,
                    Colors.teal.shade700,
                    () => context.go('/reports'),
                  ),
                  _kpi(
                    l10n.t('pos_paid'),
                    _money(_period['amount_paid']),
                    Icons.account_balance_rounded,
                    Colors.indigo.shade700,
                    () => context.go('/reports'),
                  ),
                  _kpi(
                    l10n.t('balance'),
                    _money(_period['balance_due']),
                    Icons.warning_amber_rounded,
                    Colors.red.shade700,
                    () => context.go('/pending'),
                  ),
                  _kpi(
                    l10n.t('notifications'),
                    'Active',
                    Icons.notifications_active_rounded,
                    Colors.blueGrey.shade700,
                    () => context.go('/notifications'),
                  ),
                ],
              ),
            const SizedBox(height: 32),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HR & Payroll',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.go('/hr/employees'),
                          icon: const Icon(Icons.people_alt_outlined),
                          label: Text(l10n.t('hr_employees')),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/hr/attendance'),
                          icon: const Icon(Icons.access_time_rounded),
                          label: Text(l10n.t('hr_attendance')),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/hr/leave'),
                          icon: const Icon(Icons.event_note_outlined),
                          label: Text(l10n.t('hr_leave_requests')),
                        ),
                        if (isAdmin)
                          OutlinedButton.icon(
                            onPressed: () => context.go('/hr/payroll'),
                            icon: const Icon(Icons.monetization_on_outlined),
                            label: Text(l10n.t('payroll')),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.go('/pos'),
                          icon: const Icon(Icons.point_of_sale_rounded),
                          label: Text(l10n.t('pos')),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/pending'),
                          icon: const Icon(Icons.receipt_outlined),
                          label: Text(l10n.t('pending_invoices')),
                        ),
                        if (isAdmin)
                          OutlinedButton.icon(
                            onPressed: () => context.go('/catalog'),
                            icon: const Icon(Icons.category_outlined),
                            label: Text(l10n.t('catalog')),
                          ),
                        if (isAdmin)
                          OutlinedButton.icon(
                            onPressed: () => context.go('/business'),
                            icon: const Icon(Icons.business_outlined),
                            label: Text(l10n.t('business_profile')),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpi(String label, String value, IconData icon, Color accentColor, VoidCallback onTap) {
    return SizedBox(
      width: 200,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 22, color: accentColor),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

