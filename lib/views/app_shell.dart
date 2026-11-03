import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';
import 'package:laundrypro_uae/core/design_system/responsive_layout.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/peripherals/core/storage/app_database.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/providers/locale_provider.dart';
import 'package:laundrypro_uae/widgets/brand_vector_emblem.dart';
import 'package:laundrypro_uae/widgets/global_search_dialog.dart';
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
  String _selectedBranch = 'MAIN BRANCH';
  String _selectedTerminal = 'T01';

  // Workspace Nav Items
  final List<_NavEntry> _workspaceItems = const [
    _NavEntry('/dashboard', Icons.dashboard_outlined, 'dashboard'),
    _NavEntry('/pending', Icons.access_time_rounded, 'live_orders'),
    _NavEntry('/pos', Icons.point_of_sale_rounded, 'pos'),
  ];

  // Operations Nav Items
  final List<_NavEntry> _operationItems = const [
    _NavEntry('/production', Icons.precision_manufacturing_outlined, 'production'),
    _NavEntry('/delivery', Icons.local_shipping_outlined, 'pickups_delivery'),
    _NavEntry('/customers', Icons.people_outline_rounded, 'customers'),
    _NavEntry('/vendors', Icons.handshake_outlined, 'vendors'),
  ];

  // Management Nav Items
  final List<_NavEntry> _managementItems = const [
    _NavEntry('/catalog', Icons.sell_outlined, 'catalog'),
    _NavEntry('/inventory', Icons.inventory_2_outlined, 'inventory'),
    _NavEntry('/hr/employees', Icons.badge_outlined, 'staff_payroll'),
    _NavEntry('/expenses', Icons.receipt_long_outlined, 'bookkeeping'),
    _NavEntry('/reports', Icons.bar_chart_rounded, 'reports'),
  ];

  // System Settings Nav Items
  final List<_NavEntry> _systemItems = const [
    _NavEntry('/settings', Icons.settings_outlined, 'settings'),
  ];

  void _openGlobalSearch() {
    AppDatabase? db;
    try {
      db = context.read<AppDatabase>();
    } catch (_) {}
    GlobalSearchDialog.show(context, database: db);
  }

  @override
  Widget build(BuildContext context) {
    String currentPath = '/dashboard';
    try {
      currentPath = GoRouterState.of(context).uri.toString();
    } catch (_) {
      // Graceful fallback when rendered in isolated test harness without GoRouter
      currentPath = '/dashboard';
    }
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        SingleActivator(LogicalKeyboardKey.keyK, control: true): _openGlobalSearch,
        SingleActivator(LogicalKeyboardKey.keyK, meta: true): _openGlobalSearch,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppTokens.canvas,
          body: Column(
            children: [
              // 1. APPLICATION VIEWPORT (SIDEBAR + WORKSPACE CANVAS)
              Expanded(
                child: Row(
                  children: [
                    // Desktop Expanded / Compact Modern Navy Sidebar
                    _buildSidebar(
                      context: context,
                      isExpanded: _sidebarExpanded,
                      currentPath: currentPath,
                      user: user,
                    ),

                    // Main Content Canvas Area
                    Expanded(
                      child: Column(
                        children: [
                          // Top Navigation Bar
                          _buildWorkspaceTopbar(
                            context: context,
                            currentPath: currentPath,
                            user: user,
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

              // 2. PERSISTENT HARDWARE & DATABASE HEALTH STATUS STRIP
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
                const BrandVectorEmblem(size: 36),
                if (isExpanded) ...[
                  const SizedBox(width: AppTokens.space12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'LaundryPro UAE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'BUSINESS OS',
                          style: TextStyle(
                            color: AppTokens.brandAqua,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Laundry operations, in control.',
                  style: TextStyle(
                    color: AppTokens.textMuted.withOpacity(0.8),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space8),
          ],

          const Divider(color: Color(0xFF1E293B), height: 1),

          // Scrollable Nav Lists
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8, vertical: AppTokens.space12),
              children: [
                _buildSectionHeader('WORKSPACE', isExpanded),
                ..._workspaceItems.map((item) => _buildNavItem(item, currentPath, isExpanded)),
                const SizedBox(height: AppTokens.space16),

                _buildSectionHeader('OPERATIONS', isExpanded),
                ..._operationItems.map((item) => _buildNavItem(item, currentPath, isExpanded)),
                const SizedBox(height: AppTokens.space16),

                _buildSectionHeader('MANAGEMENT', isExpanded),
                ..._managementItems.map((item) => _buildNavItem(item, currentPath, isExpanded)),
                const SizedBox(height: AppTokens.space16),

                _buildSectionHeader('SYSTEM', isExpanded),
                ..._systemItems.map((item) => _buildNavItem(item, currentPath, isExpanded)),
              ],
            ),
          ),

          // User Profile & Current Branch Status
          const Divider(color: Color(0xFF1E293B), height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space12, vertical: AppTokens.space12),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTokens.brandTeal,
                      child: Text(
                        (user?.fullName ?? 'SA').substring(0, (user?.fullName?.length ?? 2) >= 2 ? 2 : 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: AppTokens.statusReady,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTokens.brandNavy, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(width: AppTokens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'System Admin',
                          style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _selectedBranch,
                          style: const TextStyle(color: AppTokens.textMuted, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AppTokens.textMuted, size: 18),
                    onPressed: () => context.go('/login'),
                    tooltip: 'Sign Out',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isExpanded) {
    if (!isExpanded) {
      return const SizedBox(height: AppTokens.space12);
    }
    return Padding(
      padding: const EdgeInsets.only(left: AppTokens.space12, right: AppTokens.space12, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
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

          // Operational Global Search Trigger
          Expanded(
            child: InkWell(
              onTap: _openGlobalSearch,
              borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
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
                    Icon(Icons.search_rounded, size: 18, color: AppTokens.brandTeal),
                    SizedBox(width: AppTokens.space8),
                    Expanded(
                      child: Text(
                        'Search orders, customers, inventory...',
                        style: TextStyle(color: AppTokens.textSecondary, fontSize: 13),
                      ),
                    ),
                    Text('Ctrl K', style: TextStyle(color: AppTokens.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space24),

          // Interactive Branch Selector
          PopupMenuButton<String>(
            tooltip: 'Select Branch',
            initialValue: _selectedBranch,
            onSelected: (branch) {
              setState(() => _selectedBranch = branch);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'MAIN BRANCH', child: Text('MAIN BRANCH (Downtown)')),
              const PopupMenuItem(value: 'MARINA BRANCH', child: Text('MARINA BRANCH (Dubai Marina)')),
              const PopupMenuItem(value: 'PALM JUMEIRAH', child: Text('PALM JUMEIRAH (Palm Strip)')),
            ],
            child: _buildSelectorPill(icon: Icons.location_on_outlined, label: _selectedBranch),
          ),
          const SizedBox(width: AppTokens.space8),

          // Interactive Terminal Selector
          PopupMenuButton<String>(
            tooltip: 'Select Terminal',
            initialValue: _selectedTerminal,
            onSelected: (term) {
              setState(() => _selectedTerminal = term);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'T01', child: Text('T01 - Front Counter')),
              const PopupMenuItem(value: 'T02', child: Text('T02 - Express POS')),
              const PopupMenuItem(value: 'T03', child: Text('T03 - Pickup Counter')),
            ],
            child: _buildSelectorPill(icon: Icons.computer_outlined, label: _selectedTerminal),
          ),
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
