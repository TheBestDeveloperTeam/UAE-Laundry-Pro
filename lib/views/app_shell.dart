import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/providers/locale_provider.dart';
import 'package:provider/provider.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _NavItem {
  const _NavItem(this.route, this.icon, this.labelKey, {this.permission});

  final String route;
  final IconData icon;
  final String labelKey;
  final String? permission;
}

class _AppShellState extends State<AppShell> {
  bool _hrExpanded = false;

  static const _items = [
    _NavItem('/dashboard', Icons.dashboard_outlined, 'dashboard'),
    _NavItem('/pos', Icons.point_of_sale_outlined, 'pos', permission: 'sales.write'),
    _NavItem('/customers', Icons.people_outline, 'customers', permission: 'customers.read'),
    _NavItem('/vendors', Icons.store_outlined, 'vendors', permission: 'vendors.read'),
    _NavItem('/catalog', Icons.category_outlined, 'catalog', permission: 'catalog.read'),
    _NavItem('/pending', Icons.receipt_long_outlined, 'pending_invoices', permission: 'sales.read'),
    _NavItem('/production', Icons.precision_manufacturing_outlined, 'production', permission: 'sales.read'),
    _NavItem('/delivery', Icons.local_shipping_outlined, 'delivery', permission: 'delivery.read'),
    _NavItem('/challans', Icons.description_outlined, 'challans', permission: 'challans.read'),
    _NavItem('/purchasing', Icons.shopping_cart_outlined, 'purchasing', permission: 'purchasing.read'),
    _NavItem('/expenses', Icons.payments_outlined, 'expenses', permission: 'expenses.read'),
    _NavItem('/reports', Icons.bar_chart_outlined, 'reports', permission: 'reports.read'),
    _NavItem('/analytics', Icons.insights_outlined, 'analytics', permission: 'reports.read'),
    _NavItem('/notifications', Icons.notifications_outlined, 'notifications', permission: 'notifications.read'),
    _NavItem('/admin/branches', Icons.hub_outlined, 'branches', permission: 'business.read'),
    _NavItem('/admin/terminals', Icons.devices_outlined, 'terminals', permission: 'business.read'),
    _NavItem('/settings/storefront', Icons.storefront_outlined, 'storefront', permission: 'sales.read'),
    _NavItem('/customer', Icons.person_search_outlined, 'customer_portal'),
    _NavItem('/business', Icons.business_outlined, 'business_profile', permission: 'business.read'),
    _NavItem('/sync', Icons.cloud_sync_outlined, 'sync', permission: 'sync.read'),
    _NavItem('/settings', Icons.settings_outlined, 'settings', permission: 'settings.read'),
  ];

  static const _hrRoutes = [
    '/hr/employees',
    '/hr/attendance',
    '/hr/leave',
    '/hr/payroll',
  ];

  List<_NavItem> _visibleItems(List<String> permissions, bool isAdmin) {
    return _items.where((item) {
      if (item.permission == null) return true;
      if (isAdmin) return true;
      return permissions.contains(item.permission);
    }).toList();
  }

  int _selectedIndex(String location, List<_NavItem> visible) {
    final idx = visible.indexWhere((i) => i.route == location);
    if (idx >= 0) return idx;
    if (_hrRoutes.contains(location)) return -2;
    return 0;
  }

  bool _isHrRoute(String location) => _hrRoutes.contains(location);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthProvider>();
    final permissions = auth.user?.permissions ?? [];
    final isAdmin = auth.user?.role == 'administrator';
    final visible = _visibleItems(permissions, isAdmin);
    final location = GoRouterState.of(context).uri.path;
    final selected = _selectedIndex(location, visible);
    final onHr = _isHrRoute(location);
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.local_laundry_service, color: Theme.of(context).colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                l10n.t('app_name'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${l10n.t('branch')}: MAIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${l10n.t('terminal')}: T01', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
              ),
            ],
          ),
          actions: [
            if (auth.user != null)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18),
                    const SizedBox(width: 4),
                    Text(auth.user?.fullName ?? auth.user?.username ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            TextButton.icon(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: () {
                final current = Localizations.localeOf(context).languageCode;
                context.read<LocaleProvider>().setLocale(current == 'ar' ? 'en' : 'ar');
              },
              icon: const Icon(Icons.language, size: 18),
              label: Text(Localizations.localeOf(context).languageCode.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: isRtl ? 108 : 92,
                    child: NavigationRail(
                      selectedIndex: onHr ? null : (selected >= 0 ? selected : 0),
                      onDestinationSelected: (i) => context.go(visible[i].route),
                      labelType: NavigationRailLabelType.all,
                      destinations: visible
                          .map((item) => NavigationRailDestination(
                                icon: Tooltip(message: l10n.t(item.labelKey), child: Icon(item.icon)),
                                label: Text(l10n.t(item.labelKey), textAlign: TextAlign.center),
                              ))
                          .toList(),
                    ),
                  ),
                  if (_hrExpanded || onHr)
                    SizedBox(
                      width: 160,
                      child: Material(
                        elevation: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              dense: true,
                              title: Text(l10n.t('hr'), style: Theme.of(context).textTheme.titleSmall),
                              trailing: IconButton(
                                icon: Icon(_hrExpanded ? Icons.expand_less : Icons.expand_more),
                                onPressed: () => setState(() => _hrExpanded = !_hrExpanded),
                              ),
                            ),
                            if (_hrExpanded) ...[
                              _hrTile(context, l10n.t('employees'), '/hr/employees', location, Icons.badge_outlined),
                              _hrTile(context, l10n.t('attendance'), '/hr/attendance', location, Icons.schedule_outlined),
                              _hrTile(context, l10n.t('leave'), '/hr/leave', location, Icons.event_busy_outlined),
                              _hrTile(context, l10n.t('payroll'), '/hr/payroll', location, Icons.account_balance_wallet_outlined),
                            ],
                          ],
                        ),
                      ),
                    ),
                  const VerticalDivider(width: 1),
                  Expanded(child: widget.child),
                ],
              ),
            ),
            Container(
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    auth.apiHealthy ? Icons.check_circle : Icons.error_outline,
                    color: auth.apiHealthy ? Colors.green : Colors.red,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    auth.apiHealthy ? l10n.t('api_online') : l10n.t('api_offline'),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.print_outlined, size: 14, color: Colors.blueGrey),
                  const SizedBox(width: 4),
                  Text(l10n.t('printers_ready'), style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                  const SizedBox(width: 16),
                  const Icon(Icons.qr_code_scanner, size: 14, color: Colors.blueGrey),
                  const SizedBox(width: 4),
                  Text(l10n.t('scanner_ready'), style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                  const Spacer(),
                  const Icon(Icons.storage_outlined, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(l10n.t('disk_ok'), style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                  const SizedBox(width: 16),
                  Text('v1.2.1', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontFamily: 'monospace')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hrTile(BuildContext context, String label, String route, String location, IconData icon) {
    final selected = location == route;
    return ListTile(
      dense: true,
      selected: selected,
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      onTap: () => context.go(route),
    );
  }
}
