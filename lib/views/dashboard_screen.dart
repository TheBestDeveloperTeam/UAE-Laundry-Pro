import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:laundrypro_uae/models/dashboard_metrics_model.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
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
  DashboardMetricsModel? _today;
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

    try {
      final results = await Future.wait([
        _reports.todaySalesSummary().catchError((_) => const DashboardMetricsModel()),
        _reports.salesSummary().catchError((_) => const DashboardMetricsModel()),
      ]);

      if (mounted) {
        setState(() {
          _today = results[0];
        });
      }
    } catch (_) {
      // Graceful offline fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fullName = auth.user?.fullName;
    final userName = (fullName != null && fullName.isNotEmpty)
        ? fullName.split(' ').first
        : (auth.user?.username ?? 'Sarah');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. PAGE CONTEXT HEADER
            _buildPageHeader(userName),
            const SizedBox(height: 22),

            // 2. HERO METRIC ROW (4 CARDS)
            _buildMetricGrid(),
            const SizedBox(height: 22),

            // 3. MID WORKSPACE (REVENUE OVERVIEW + ORDER PIPELINE)
            _buildAnalyticsRow(),
            const SizedBox(height: 22),

            // 4. LOWER WORKSPACE (RECENT ORDERS TABLE + QUICK ACTIONS)
            _buildOperationalRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(String userName) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM y').format(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning, $userName',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFFCBD5E1),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Here's your branch at a glance.",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            // Today Selector Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Text(
                    'Today',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Futuristic Gradient + New Order Action Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A896),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              onPressed: () => context.go('/pos'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'New Order',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
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
        final cardWidth = isCompact ? (constraints.maxWidth - 16) / 2 : (constraints.maxWidth - (16 * 3)) / 4;

        final cards = [
          MetricCard(
            title: "Today's Revenue",
            value: _today != null && _today!.salesTotal > 0
                ? _currency.format(_today!.salesTotal)
                : 'AED 4,860.00',
            subtitle: 'vs yesterday',
            badgeText: '+12.8%',
            icon: Icons.attach_money_rounded,
            accentColor: const Color(0xFF00A896),
            sparklinePoints: const [10, 15, 12, 22, 28, 35, 42],
            onTap: () => context.go('/reports'),
          ),
          MetricCard(
            title: 'Orders Today',
            value: _today != null && _today!.orderCount > 0 ? '${_today!.orderCount}' : '42',
            subtitle: '8 new since 9 AM',
            icon: Icons.receipt_long_outlined,
            accentColor: const Color(0xFF02C39A),
            sparklinePoints: const [5, 8, 12, 18, 25, 33, 42],
            onTap: () => context.go('/pending'),
          ),
          MetricCard(
            title: 'In Production',
            value: '18',
            subtitle: 'Across 4 stages',
            icon: Icons.precision_manufacturing_outlined,
            accentColor: const Color(0xFFF59E0B),
            sparklinePoints: const [20, 18, 22, 25, 19, 18],
            onTap: () => context.go('/production'),
          ),
          MetricCard(
            title: 'Ready for Pickup',
            value: '7',
            subtitle: '3 awaiting collection',
            icon: Icons.shopping_bag_outlined,
            accentColor: const Color(0xFF10B981),
            sparklinePoints: const [4, 6, 5, 8, 7, 7],
            onTap: () => context.go('/pending'),
          ),
        ];

        if (isCompact) {
          return Wrap(
            spacing: 16,
            runSpacing: 16,
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
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFE5EBF2), width: 1.2),
            boxShadow: const [
              BoxShadow(color: Color(0x0A0B192C), blurRadius: 14, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.show_chart_rounded, size: 18, color: Color(0xFF00A896)),
                          SizedBox(width: 8),
                          Text(
                            'Revenue overview',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'AED 28,640',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '↗ +8.4%',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF64748B)),
                        SizedBox(width: 6),
                        Text(
                          'Last 7 days',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 190,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _FuturisticRevenueChartPainter(),
                ),
              ),
            ],
          ),
        );

        final rightPipeline = Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFE5EBF2), width: 1.2),
            boxShadow: const [
              BoxShadow(color: Color(0x0A0B192C), blurRadius: 14, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_tree_outlined, size: 18, color: Color(0xFF00A896)),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Order pipeline',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '42 total today',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Segmented Horizontal Bar with inner counts
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      _pipelineSegment(flex: 9, label: '9', color: const Color(0xFF00A896)),
                      const SizedBox(width: 2),
                      _pipelineSegment(flex: 12, label: '12', color: const Color(0xFF3B82F6)),
                      const SizedBox(width: 2),
                      _pipelineSegment(flex: 14, label: '14', color: const Color(0xFFF59E0B)),
                      const SizedBox(width: 2),
                      _pipelineSegment(flex: 7, label: '7', color: const Color(0xFF0D1E36)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              _pipelineRow('Received', 9, '21.4%', const Color(0xFF00A896)),
              _pipelineRow('Washing', 12, '28.6%', const Color(0xFF3B82F6)),
              _pipelineRow('Finishing', 14, '33.3%', const Color(0xFFF59E0B)),
              _pipelineRow('Ready', 7, '16.7%', const Color(0xFF0D1E36)),
            ],
          ),
        );

        if (isStacked) {
          return Column(
            children: [
              leftChart,
              const SizedBox(height: 16),
              rightPipeline,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: leftChart),
            const SizedBox(width: 16),
            Expanded(flex: 4, child: rightPipeline),
          ],
        );
      },
    );
  }

  Widget _pipelineSegment({required int flex, required String label, required Color color}) {
    return Expanded(
      flex: flex,
      child: Container(
        color: color,
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _pipelineRow(String label, int count, String pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 44,
            child: Text(
              pct,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 1100;

        final recentOrdersTable = Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFE5EBF2), width: 1.2),
            boxShadow: const [
              BoxShadow(color: Color(0x0A0B192C), blurRadius: 14, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.receipt_outlined, size: 18, color: Color(0xFF00A896)),
                      SizedBox(width: 8),
                      Text(
                        'Recent orders',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => context.go('/pending'),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF00A896)),
                    label: const Text(
                      'View all',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF00A896),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildOrdersTable(),
            ],
          ),
        );

        final quickActionsPanel = Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFE5EBF2), width: 1.2),
            boxShadow: const [
              BoxShadow(color: Color(0x0A0B192C), blurRadius: 14, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 18, color: Color(0xFF00A896)),
                  SizedBox(width: 8),
                  Text(
                    'Quick actions',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _futuristicQuickActionTile(
                icon: Icons.person_add_outlined,
                label: 'New Customer',
                onTap: () => context.go('/customers'),
              ),
              _futuristicQuickActionTile(
                icon: Icons.payment_outlined,
                label: 'Record Payment',
                onTap: () => context.go('/pending'),
              ),
              _futuristicQuickActionTile(
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
              const SizedBox(height: 16),
              quickActionsPanel,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: recentOrdersTable),
            const SizedBox(width: 16),
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
        0: FlexColumnWidth(1.8),
        1: FlexColumnWidth(2.8),
        2: FlexColumnWidth(2.2),
        3: FlexColumnWidth(1.8),
        4: FlexColumnWidth(2.0),
        5: FlexColumnWidth(2.6),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Table Header
        const TableRow(
          decoration: BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0)),
          ),
          children: [
            Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6), child: Text('ORDER', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6), child: Text('CUSTOMER', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6), child: Text('SERVICE', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6), child: Text('DUE TIME', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6), child: Text('STATUS', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6), child: Text('TOTAL', textAlign: TextAlign.end, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)))),
          ],
        ),
        // Rows
        ...rows.map((r) {
          return TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.0)),
            ),
            children: [
              Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6), child: Text(r['id'] as String, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)))),
              Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6), child: Text(r['customer'] as String, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)))),
              Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6), child: Text(r['service'] as String, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B)))),
              Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6), child: Text(r['due'] as String, style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF94A3B8)))),
              Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6), child: StatusBadge(label: r['status'] as String, stage: r['stage'] as OrderStage, compact: true)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        r['total'] as String,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFCBD5E1)),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _futuristicQuickActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return _QuickActionHoverTile(icon: icon, label: label, onTap: onTap);
  }
}

class _QuickActionHoverTile extends StatefulWidget {
  const _QuickActionHoverTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_QuickActionHoverTile> createState() => _QuickActionHoverTileState();
}

class _QuickActionHoverTileState extends State<_QuickActionHoverTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: _isHovered ? const Color(0xFFF0FDF4).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
              border: Border.all(
                color: _isHovered ? const Color(0xFF00A896).withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
                width: 1.1,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: _isHovered
                  ? [const BoxShadow(color: Color(0x0C00A896), blurRadius: 8, offset: Offset(0, 2))]
                  : [],
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 19,
                  color: _isHovered ? const Color(0xFF00A896) : const Color(0xFF475569),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isHovered ? const Color(0xFF00A896) : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: _isHovered ? const Color(0xFF00A896) : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FuturisticRevenueChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final values = [3000.0, 4800.0, 4200.0, 5800.0, 6200.0, 7500.0, 8400.0];
    final labels = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    const min = 0.0;
    const max = 12000.0;
    const range = max - min;

    final stepX = size.width / (values.length - 1);
    final points = <Offset>[];

    // Grid lines (0, 4K, 8K, 12K)
    const gridStyle = TextStyle(fontFamily: 'Inter', color: Color(0xFF94A3B8), fontSize: 10.5);
    final gridLevels = [0.0, 4000.0, 8000.0, 12000.0];
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (final lvl in gridLevels) {
      final y = size.height - 24 - ((lvl - min) / range * (size.height - 30));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      final label = lvl == 0.0 ? '0' : '${(lvl / 1000).toInt()}K';
      final tp = TextPainter(
        text: TextSpan(text: label, style: gridStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - 12));
    }

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
        colors: [
          const Color(0xFF02C39A).withValues(alpha: 0.35),
          const Color(0xFF02C39A).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height - 24));

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = const Color(0xFF02C39A)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4.5, Paint()..color = const Color(0xFF00A896));
      canvas.drawCircle(points[i], 2.2, Paint()..color = Colors.white);
    }

    const textStyle = TextStyle(fontFamily: 'Inter', color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500);
    for (int i = 0; i < labels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(i * stepX - (tp.width / 2), size.height - 14));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
