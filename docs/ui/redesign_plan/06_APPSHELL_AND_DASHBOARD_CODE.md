# LaundryPro UAE — AppShell & Dashboard Implementation Code
## Complete Dart Code: Universal Shell, Workspace Topbar & Hero Dashboard

---

### File 1: `lib/views/app_shell.dart`

```dart
// lib/views/app_shell.dart
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
  bool _sidebarExpanded = true;

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
    final l10n = context.l10n;
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
                  // 1. DARK NAVY SIDEBAR
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
                  const Column(
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
                      ),
                      Text(
                        'BUSINESS OS',
                        style: TextStyle(
                          color: AppTokens.brandAqua,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
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
```

---

### File 2: `lib/views/dashboard_screen.dart`

```dart
// lib/views/dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';
import 'package:laundrypro_uae/core/design_system/responsive_layout.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/models/dashboard_metrics_model.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/services/notification_service.dart';
import 'package:laundrypro_uae/services/reports_service.dart';
import 'package:laundrypro_uae/widgets/metric_card.dart';
import 'package:laundrypro_uae/widgets/status_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.reportsService});
  final ReportsService? reportsService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ReportsService _reports;
  final NotificationService _notifications = NotificationService();
  DashboardMetricsModel? _today;
  DashboardMetricsModel? _period;
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;
  late NumberFormat _currency;

  @override
  void initState() {
    super.initState();
    _currency = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);
    _reports = widget.reportsService ?? ReportsService();
    _loadSummary();
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
      final results = await Future.wait([
        _reports.todaySalesSummary().catchError((_) => DashboardMetricsModel.empty()),
        _reports.salesSummary().catchError((_) => DashboardMetricsModel.empty()),
      ]);

      if (mounted) {
        setState(() {
          _today = results[0];
          _period = results[1];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not sync live statistics. Displaying local cache.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.fullName?.split(' ').first ?? 'Sarah';

    return Scaffold(
      backgroundColor: AppTokens.canvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space24, vertical: AppTokens.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. PAGE CONTEXT HEADER
            _buildPageHeader(userName),
            const SizedBox(height: AppTokens.space20),

            // 2. HERO METRIC ROW (4 CARDS)
            _buildMetricGrid(),
            const SizedBox(height: AppTokens.space20),

            // 3. MID WORKSPACE (REVENUE OVERVIEW + ORDER PIPELINE)
            _buildAnalyticsRow(),
            const SizedBox(height: AppTokens.space20),

            // 4. LOWER WORKSPACE (RECENT ORDERS TABLE + QUICK ACTIONS)
            _buildOperationalRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good morning, $userName', style: AppTokens.pageHeading),
            const SizedBox(height: 2),
            const Text(
              "Here's your branch at a glance.",
              style: TextStyle(fontSize: 13, color: AppTokens.textSecondary),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTokens.surfacePrimary,
                borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                border: Border.all(color: AppTokens.borderSubtle),
              ),
              child: const Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: AppTokens.textSecondary),
                  SizedBox(width: 8),
                  Text('Today', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.space12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.brandTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium)),
                elevation: 0,
              ),
              onPressed: () => context.go('/pos'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Order', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1100;
        final cardWidth = isCompact ? (constraints.maxWidth - AppTokens.space16) / 2 : (constraints.maxWidth - (AppTokens.space16 * 3)) / 4;

        final cards = [
          MetricCard(
            title: "Today's Revenue",
            value: _currency.format(_today?.totalSales ?? 4860.0),
            subtitle: 'vs yesterday',
            badgeText: '+12.8%',
            icon: Icons.attach_money_rounded,
            accentColor: AppTokens.brandTeal,
            sparklinePoints: const [10, 15, 12, 22, 28, 35, 42],
            onTap: () => context.go('/reports'),
          ),
          MetricCard(
            title: 'Orders Today',
            value: '${_today?.ordersCount ?? 42}',
            subtitle: '8 new since 9 AM',
            icon: Icons.description_outlined,
            accentColor: AppTokens.brandAqua,
            sparklinePoints: const [5, 8, 12, 18, 25, 33, 42],
            onTap: () => context.go('/pending'),
          ),
          MetricCard(
            title: 'In Production',
            value: '18',
            subtitle: 'Across 4 stages',
            icon: Icons.precision_manufacturing_outlined,
            accentColor: AppTokens.statusFinishing,
            sparklinePoints: const [20, 18, 22, 25, 19, 18],
            onTap: () => context.go('/production'),
          ),
          MetricCard(
            title: 'Ready for Pickup',
            value: '7',
            subtitle: '3 awaiting collection',
            icon: Icons.shopping_bag_outlined,
            accentColor: AppTokens.statusReady,
            sparklinePoints: const [4, 6, 5, 8, 7, 7],
            onTap: () => context.go('/pending'),
          ),
        ];

        if (isCompact) {
          return Wrap(
            spacing: AppTokens.space16,
            runSpacing: AppTokens.space16,
            children: cards.map((c) => SizedBox(width: cardWidth, child: c)).toList(),
          );
        }

        return Row(
          children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
        );
      },
    );
  }

  Widget _buildAnalyticsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 1100;

        final leftChart = Container(
          padding: const EdgeInsets.all(AppTokens.space20),
          decoration: AppTokens.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Revenue overview', style: AppTokens.sectionHeading),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text('AED 28,640', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTokens.textPrimary)),
                          SizedBox(width: 8),
                          Text('↗ +8.4%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTokens.statusReady)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTokens.surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                      border: Border.all(color: AppTokens.borderSubtle),
                    ),
                    child: const Row(
                      children: [
                        Text('Last 7 days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space20),
              SizedBox(
                height: 180,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _RevenueOverviewChartPainter(),
                ),
              ),
            ],
          ),
        );

        final rightPipeline = Container(
          padding: const EdgeInsets.all(AppTokens.space20),
          decoration: AppTokens.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order pipeline', style: AppTokens.sectionHeading),
                  Text('42 total today', style: TextStyle(fontSize: 12, color: AppTokens.textSecondary)),
                ],
              ),
              const SizedBox(height: AppTokens.space16),

              // Segmented Horizontal Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: const [
                      Expanded(flex: 9, child: ColoredBox(color: AppTokens.statusReceived)),
                      SizedBox(width: 2),
                      Expanded(flex: 12, child: ColoredBox(color: AppTokens.statusWashing)),
                      SizedBox(width: 2),
                      Expanded(flex: 14, child: ColoredBox(color: AppTokens.statusFinishing)),
                      SizedBox(width: 2),
                      Expanded(flex: 7, child: ColoredBox(color: AppTokens.brandNavy)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space16),

              _pipelineRow('Received', 9, '21.4%', AppTokens.statusReceived),
              _pipelineRow('Washing', 12, '28.6%', AppTokens.statusWashing),
              _pipelineRow('Finishing', 14, '33.3%', AppTokens.statusFinishing),
              _pipelineRow('Ready', 7, '16.7%', AppTokens.brandNavy),
            ],
          ),
        );

        if (isStacked) {
          return Column(
            children: [
              leftChart,
              const SizedBox(height: AppTokens.space16),
              rightPipeline,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: leftChart),
            const SizedBox(width: AppTokens.space16),
            Expanded(flex: 4, child: rightPipeline),
          ],
        );
      },
    );
  }

  Widget _pipelineRow(String label, int count, String pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTokens.textSecondary))),
          Text('$count', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTokens.textPrimary)),
          const SizedBox(width: 16),
          Text(pct, style: const TextStyle(fontSize: 12, color: AppTokens.textMuted)),
        ],
      ),
    );
  }

  Widget _buildOperationalRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 1100;

        final recentOrdersTable = Container(
          padding: const EdgeInsets.all(AppTokens.space20),
          decoration: AppTokens.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent orders', style: AppTokens.sectionHeading),
                  TextButton(
                    onPressed: () => context.go('/pending'),
                    child: const Text('View all →', style: TextStyle(color: AppTokens.brandTeal, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space12),
              _buildOrdersTable(),
            ],
          ),
        );

        final quickActionsPanel = Container(
          padding: const EdgeInsets.all(AppTokens.space20),
          decoration: AppTokens.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 18, color: AppTokens.brandTeal),
                  SizedBox(width: 6),
                  Text('Quick actions', style: AppTokens.sectionHeading),
                ],
              ),
              const SizedBox(height: AppTokens.space16),
              _quickActionTile(
                icon: Icons.person_add_outlined,
                label: 'New Customer',
                onTap: () => context.go('/customers'),
              ),
              _quickActionTile(
                icon: Icons.payment_outlined,
                label: 'Record Payment',
                onTap: () => context.go('/pending'),
              ),
              _quickActionTile(
                icon: Icons.inventory_2_outlined,
                label: 'Stock Receive',
                onTap: () => context.go('/inventory'),
              ),
            ],
          ),
        );

        if (isStacked) {
          return Column(
            children: [
              recentOrdersTable,
              const SizedBox(height: AppTokens.space16),
              quickActionsPanel,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: recentOrdersTable),
            const SizedBox(width: AppTokens.space16),
            Expanded(flex: 4, child: quickActionsPanel),
          ],
        );
      },
    );
  }

  Widget _buildOrdersTable() {
    final rows = [
      {'id': 'LP-10482', 'customer': 'Aisha Khan', 'service': 'Wash & Fold', 'due': '10:30 AM', 'status': 'Ready', 'stage': OrderStage.ready, 'total': 'AED 86.00'},
      {'id': 'LP-10481', 'customer': 'Omar Hassan', 'service': 'Dry Cleaning', 'due': '11:00 AM', 'status': 'Finishing', 'stage': OrderStage.finishing, 'total': 'AED 145.00'},
      {'id': 'LP-10480', 'customer': 'Mariam Ali', 'service': 'Abaya Care', 'due': '11:30 AM', 'status': 'Washing', 'stage': OrderStage.washing, 'total': 'AED 72.00'},
      {'id': 'LP-10479', 'customer': 'Zayd Ahmed', 'service': 'Premium Press', 'due': '12:00 PM', 'status': 'Received', 'stage': OrderStage.received, 'total': 'AED 55.00'},
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.0),
        1: FlexColumnWidth(3.0),
        2: FlexColumnWidth(2.5),
        3: FlexColumnWidth(2.0),
        4: FlexColumnWidth(2.2),
        5: FlexColumnWidth(2.2),
      },
      children: rows.map((r) {
        return TableRow(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTokens.borderSubtle, width: 0.8)),
          ),
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(r['id'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(r['customer'] as String, style: const TextStyle(fontSize: 13))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(r['service'] as String, style: const TextStyle(fontSize: 13, color: AppTokens.textSecondary))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(r['due'] as String, style: const TextStyle(fontSize: 13, color: AppTokens.textMuted))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: StatusBadge(label: r['status'] as String, stage: r['stage'] as OrderStage, compact: true)),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(r['total'] as String, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          ],
        );
      }).toList(),
    );
  }

  Widget _quickActionTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space12, vertical: AppTokens.space12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTokens.borderSubtle),
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTokens.brandTeal),
              const SizedBox(width: AppTokens.space12),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              const Icon(Icons.chevron_right, size: 18, color: AppTokens.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueOverviewChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final values = [3000.0, 4800.0, 4200.0, 5800.0, 6200.0, 7500.0, 8400.0];
    final labels = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final min = 0.0;
    final max = 12000.0;
    final range = max - min;

    final stepX = size.width / (values.length - 1);
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - 24 - ((values[i] - min) / range * (size.height - 30));
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      path.quadraticBezierTo(p0.dx, p0.dy, (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
    }
    path.lineTo(points.last.dx, points.last.dy);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height - 24)
      ..lineTo(0, size.height - 24)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppTokens.brandAqua.withOpacity(0.35), AppTokens.brandAqua.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height - 24));

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = AppTokens.brandAqua
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 3.5, Paint()..color = AppTokens.brandTeal);
      canvas.drawCircle(points[i], 2.0, Paint()..color = Colors.white);
    }

    final textStyle = const TextStyle(color: AppTokens.textMuted, fontSize: 11);
    for (int i = 0; i < labels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(i * stepX - (tp.width / 2), size.height - 14));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

