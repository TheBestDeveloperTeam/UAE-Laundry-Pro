import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';
import 'package:laundrypro_uae/core/design_system/responsive_layout.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/providers/locale_provider.dart';
import 'package:laundrypro_uae/widgets/hardware_status_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _NavEntry {
  const _NavEntry(this.route, this.icon, this.labelKey, {this.permission});
  final String route;
  final IconData icon;
  final String labelKey;
  final String? permission;
}

class _AppShellState extends State<AppShell> {
  final bool _sidebarExpanded = true;

  // Workspace Nav Items
  static const _workspaceGroup = [
    _NavEntry('/dashboard', Icons.dashboard_rounded, 'dashboard'),
    _NavEntry('/pending', Icons.access_time_rounded, 'live_orders', permission: 'sales.read'),
    _NavEntry('/pos', Icons.point_of_sale_rounded, 'pos', permission: 'sales.write'),
  ];

  // Operations Nav Items
  static const _operationsGroup = [
    _NavEntry('/production', Icons.settings_suggest_rounded, 'production', permission: 'sales.read'),
    _NavEntry('/delivery', Icons.local_shipping_rounded, 'pickups_delivery', permission: 'delivery.read'),
    _NavEntry('/customers', Icons.group_rounded, 'customers', permission: 'customers.read'),
    _NavEntry('/vendors', Icons.store_rounded, 'vendors', permission: 'vendors.read'),
  ];

  // Management Nav Items
  static const _managementGroup = [
    _NavEntry('/catalog', Icons.sell_rounded, 'catalog', permission: 'catalog.read'),
    _NavEntry('/inventory', Icons.inventory_2_rounded, 'inventory', permission: 'inventory.read'),
    _NavEntry('/hr/payroll', Icons.badge_rounded, 'staff_payroll', permission: 'business.read'),
    _NavEntry('/expenses', Icons.account_balance_wallet_rounded, 'bookkeeping', permission: 'expenses.read'),
    _NavEntry('/reports', Icons.bar_chart_rounded, 'reports', permission: 'reports.read'),
  ];

  // System Nav Items
  static const _systemGroup = [
    _NavEntry('/admin/branches', Icons.hub_rounded, 'branches_terminals', permission: 'business.read'),
    _NavEntry('/settings', Icons.settings_rounded, 'settings', permission: 'settings.read'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    final screenType = ResponsiveLayout.getScreenType(context);
    final autoCompact = screenType == DeviceScreenType.compactDesktop;
    final isExpanded = !autoCompact && _sidebarExpanded;

    String currentPath = '/dashboard';
    try {
      currentPath = GoRouterState.of(context).uri.path;
    } catch (_) {}

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTokens.canvas,
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  // 1. DARK NAVY SIDEBAR (260px / 76px)
                  _buildSidebar(
                    context: context,
                    isExpanded: isExpanded,
                    currentPath: currentPath,
                    user: auth.user,
                  ),

                  // 2. MAIN WORKSPACE AREA (TOPBAR + SCROLLABLE CANVAS)
                  Expanded(
                    child: Column(
                      children: [
                        // Workspace Topbar (Breadcrumbs, Search, Branch, Terminal, Profile)
                        _buildWorkspaceTopbar(
                          context: context,
                          currentPath: currentPath,
                          user: auth.user,
                          isRtl: isRtl,
                        ),

                        // Child Screen Content Canvas
                        Expanded(
                          child: widget.child,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. PERSISTENT HARDWARE & DATABASE HEALTH STATUS STRIP
            const HardwareStatusBar(
              isDbConnected: true,
              isPrinterReady: true,
              isScannerReady: true,
              lastSyncTime: '10:42 AM',
              version: 'v2.1.0',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar({
    required BuildContext context,
    required bool isExpanded,
    required String currentPath,
    required dynamic user,
  }) {
    final sidebarWidth = isExpanded ? 260.0 : 76.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: sidebarWidth,
      color: AppTokens.brandNavy,
      child: Column(
        children: [
          // Logo & Brand Lockup
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTokens.brandTeal,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                  ),
                  child: const Icon(Icons.local_laundry_service_rounded, color: Colors.white, size: 22),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: AppTokens.space12),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LaundryPro UAE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'BUSINESS OS',
                          style: TextStyle(
                            color: AppTokens.brandAqua,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppTokens.brandNavyBorder),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space12, horizontal: AppTokens.space8),
              children: [
                _buildGroupHeader('WORKSPACE', isExpanded),
                ..._workspaceGroup.map((item) => _buildNavItem(item, currentPath, isExpanded)),
                const SizedBox(height: AppTokens.space12),

                _buildGroupHeader('OPERATIONS', isExpanded),
                ..._operationsGroup.map((item) => _buildNavItem(item, currentPath, isExpanded)),
                const SizedBox(height: AppTokens.space12),

                _buildGroupHeader('MANAGEMENT', isExpanded),
                ..._managementGroup.map((item) => _buildNavItem(item, currentPath, isExpanded)),
                const SizedBox(height: AppTokens.space12),

                _buildGroupHeader('SYSTEM', isExpanded),
                ..._systemGroup.map((item) => _buildNavItem(item, currentPath, isExpanded)),
              ],
            ),
          ),

          // User Profile Block at Bottom
          Container(
            padding: const EdgeInsets.all(AppTokens.space12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTokens.brandNavyBorder, width: 1.0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTokens.brandTeal,
                  child: Text(
                    user?.username?.substring(0, 1).toUpperCase() ?? 'A',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: AppTokens.space10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? user?.username ?? 'System Admin',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Main Branch',
                          style: TextStyle(color: AppTokens.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AppTokens.textMuted, size: 18),
                    onPressed: () => context.read<AuthProvider>().logout(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String title, bool isExpanded) {
    if (!isExpanded) return const SizedBox(height: AppTokens.space8);
    return Padding(
      padding: const EdgeInsets.only(left: AppTokens.space12, right: AppTokens.space12, top: AppTokens.space8, bottom: AppTokens.space4),
      child: Text(title, style: AppTokens.groupLabel),
    );
  }

  Widget _buildNavItem(_NavEntry item, String currentPath, bool isExpanded) {
    final l10n = context.l10n;
    final isActive = currentPath.startsWith(item.route);

    return InkWell(
      onTap: () => context.go(item.route),
      borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space12),
        decoration: BoxDecoration(
          color: isActive ? AppTokens.brandTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: isActive ? Colors.white : AppTokens.textMuted, size: 20),
            if (isExpanded) ...[
              const SizedBox(width: AppTokens.space12),
              Expanded(
                child: Text(
                  l10n.t(item.labelKey),
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFFC7D2FE),
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceTopbar({
    required BuildContext context,
    required String currentPath,
    required dynamic user,
    required bool isRtl,
  }) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space24),
      decoration: const BoxDecoration(
        color: AppTokens.surfacePrimary,
        border: Border(bottom: BorderSide(color: AppTokens.borderSubtle, width: 1.0)),
      ),
      child: Row(
        children: [
          // Breadcrumbs
          Row(
            children: [
              const Icon(Icons.home_outlined, size: 18, color: AppTokens.textMuted),
              const SizedBox(width: AppTokens.space8),
              Text(
                'Workspace / ${_formatPath(currentPath)}',
                style: const TextStyle(fontSize: 13, color: AppTokens.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(width: AppTokens.space24),

          // Global Search Field
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space12),
              decoration: BoxDecoration(
                color: AppTokens.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                border: Border.all(color: AppTokens.borderSubtle),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, size: 18, color: AppTokens.textMuted),
                  SizedBox(width: AppTokens.space8),
                  Expanded(
                    child: Text(
                      'Search orders, customers, invoices...',
                      style: TextStyle(color: AppTokens.textMuted, fontSize: 13),
                    ),
                  ),
                  Text('Ctrl K', style: TextStyle(color: AppTokens.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space24),

          // Branch & Terminal Selectors
          _buildSelectorPill(icon: Icons.location_on_outlined, label: 'MAIN BRANCH'),
          const SizedBox(width: AppTokens.space8),
          _buildSelectorPill(icon: Icons.computer_outlined, label: 'T01'),
          const SizedBox(width: AppTokens.space12),

          // Bilingual Language Switcher (EN | العربية)
          InkWell(
            onTap: () {
              final curr = Localizations.localeOf(context).languageCode;
              context.read<LocaleProvider>().setLocale(curr == 'ar' ? 'en' : 'ar');
            },
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppTokens.borderSubtle),
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              ),
              child: Text(
                isRtl ? 'English' : 'العربية',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTokens.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space12),

          // Notifications Bell
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 20, color: AppTokens.textSecondary),
            onPressed: () => context.go('/notifications'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: AppTokens.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTokens.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTokens.textPrimary)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 16, color: AppTokens.textMuted),
        ],
      ),
    );
  }

  String _formatPath(String path) {
    if (path.isEmpty || path == '/') return 'Dashboard';
    final clean = path.replaceAll('/', ' ').trim();
    return clean.substring(0, 1).toUpperCase() + clean.substring(1);
  }
}
