import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/services/notification_service.dart';
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
  final NotificationService _notifications = NotificationService();
  Map<String, dynamic> _today = {};
  Map<String, dynamic> _period = {};
  Map<String, dynamic> _inventory = {};
  bool _loading = true;
  String? _error;
  int _unreadCount = 0;
  Timer? _refreshTimer;

  // Uses default currency, but should ideally be pulled from settings.
  // We'll leave the symbol dynamic to be fetched.
  late NumberFormat _currency;

  @override
  void initState() {
    super.initState();
    _currency = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);
    _reports = widget.reportsService ?? ReportsService();
    _loadSummary();
    
    // R-026: Auto-refresh every 60 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _loadSummary());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _notifications.generateAlerts();
      final notifs = await _notifications.list(unreadOnly: true);

      final results = await Future.wait([
        _reports.todaySalesSummary(),
        _reports.salesSummary(),
        _reports.inventoryValuation(),
      ]);
      if (mounted) {
        setState(() {
          _today = results[0];
          _period = results[1];
          _inventory = results[2];
          _unreadCount = notifs.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load dashboard data.';
          _loading = false;
        });
      }
    }
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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => context.go('/notifications'),
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                    const Spacer(),
                    TextButton(onPressed: _loadSummary, child: const Text('Retry')),
                  ],
                ),
              ),
            Text(
              l10n.t('today'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_loading && _today.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _kpi(
                    l10n.t('pos_total'),
                    _money(_today['grand_total']),
                    Icons.storefront_rounded,
                    Colors.green.shade700,
                    () => context.go('/reports'),
                    trend: 1,
                  ),
                  _kpi(
                    l10n.t('dashboard_outstanding'),
                    _money(_today['balance_due']),
                    Icons.receipt_long_rounded,
                    Colors.orange.shade800,
                    () => context.go('/pending'),
                    trend: -1,
                  ),
                  _kpi(
                    l10n.t('orders'),
                    '${_today['order_count'] ?? 0}',
                    Icons.shopping_bag_rounded,
                    Colors.blue.shade700,
                    () => context.go('/production'),
                    trend: 1,
                  ),
                  _kpi(
                    l10n.t('dashboard_low_stock'),
                    '${_inventory['product_count'] ?? 0}',
                    Icons.inventory_2_rounded,
                    Colors.purple.shade700,
                    () => context.go('/catalog'),
                    trend: 0,
                  ),
                ],
              ),
            const SizedBox(height: 32),
            Text(
              l10n.t('reports_sales'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (!_loading || _period.isNotEmpty)
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
                    trend: 1,
                  ),
                  _kpi(
                    l10n.t('pos_paid'),
                    _money(_period['amount_paid']),
                    Icons.account_balance_rounded,
                    Colors.indigo.shade700,
                    () => context.go('/reports'),
                    trend: 1,
                  ),
                  _kpi(
                    l10n.t('balance'),
                    _money(_period['balance_due']),
                    Icons.warning_amber_rounded,
                    Colors.red.shade700,
                    () => context.go('/pending'),
                    trend: -1,
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
            const SizedBox(height: 40),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
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
                                onPressed: () => context.go('/customers'),
                                icon: const Icon(Icons.person_add_alt_1_outlined),
                                label: Text(l10n.t('customers')),
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
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HR & Payroll',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpi(String label, String value, IconData icon, Color accentColor, VoidCallback onTap, {int trend = 0}) {
    return SizedBox(
      width: 220,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 24, color: accentColor),
                    ),
                    if (trend != 0)
                      Icon(
                        trend > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: trend > 0 ? Colors.green.shade600 : Colors.red.shade500,
                        size: 20,
                      )
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
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
