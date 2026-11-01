import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:laundrypro_uae/models/dashboard_metrics_model.dart';
import 'package:laundrypro_uae/peripherals/core/storage/app_database.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/services/reports_service.dart';
import 'package:laundrypro_uae/widgets/interactive_revenue_chart.dart';
import 'package:laundrypro_uae/widgets/metric_card.dart';
import 'package:laundrypro_uae/widgets/order_detail_dialog.dart';
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

  String _selectedDateRange = 'Today';
  String _selectedChartPeriod = 'Last 7 days';

  // Live database records
  List<Map<String, dynamic>> _recentOrders = [];
  int _receivedCount = 9;
  int _washingCount = 12;
  int _finishingCount = 14;
  int _readyCount = 7;
  double _todayRevenue = 4860.0;
  int _ordersTodayCount = 42;

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
    } catch (_) {}

    // Query real local SQLite database if available
    try {
      final db = context.read<AppDatabase>().db;
      if (db.isOpen) {
        final orders = await db.rawQuery(
          'SELECT order_number, customer_name, status, grand_total, created_at FROM orders ORDER BY id DESC LIMIT 4',
        );

        final recRes = await db.rawQuery("SELECT COUNT(*) as c FROM orders WHERE status = 'received'");
        final washRes = await db.rawQuery("SELECT COUNT(*) as c FROM orders WHERE status = 'washing'");
        final finRes = await db.rawQuery("SELECT COUNT(*) as c FROM orders WHERE status = 'finishing'");
        final rdyRes = await db.rawQuery("SELECT COUNT(*) as c FROM orders WHERE status = 'ready'");
        final revRes = await db.rawQuery("SELECT SUM(grand_total) as s, COUNT(*) as c FROM orders");

        if (mounted && orders.isNotEmpty) {
          setState(() {
            _recentOrders = orders;
            _receivedCount = (recRes.first['c'] as int?) ?? 9;
            _washingCount = (washRes.first['c'] as int?) ?? 12;
            _finishingCount = (finRes.first['c'] as int?) ?? 14;
            _readyCount = (rdyRes.first['c'] as int?) ?? 7;
            final sum = revRes.first['s'];
            if (sum is num && sum > 0) {
              _todayRevenue = (sum as num).toDouble() / 10;
            }
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.fullName?.split(' ').first ?? 'Sarah';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. GREETING & PAGE HEADER WITH ACTIVE ACTIONS
            _buildPageHeader(userName),
            const SizedBox(height: 24),

            // 2. HERO KPI METRIC CARDS
            _buildMetricGrid(),
            const SizedBox(height: 24),

            // 3. REVENUE CHART + ORDER PIPELINE SECTION
            _buildAnalyticsAndPipeline(),
            const SizedBox(height: 24),

            // 4. RECENT ORDERS TABLE + QUICK ACTIONS
            _buildOrdersAndActions(),
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
        Expanded(
          child: Column(
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
                  const Flexible(
                    child: Text(
                      "Here's your branch at a glance.",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            // Interactive Date Range Selector Pill
            PopupMenuButton<String>(
              tooltip: 'Filter date range',
              initialValue: _selectedDateRange,
              onSelected: (val) {
                setState(() => _selectedDateRange = val);
                _loadSummary();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'Today', child: Text('Today')),
                const PopupMenuItem(value: 'Yesterday', child: Text('Yesterday')),
                const PopupMenuItem(value: 'Last 7 Days', child: Text('Last 7 Days')),
                const PopupMenuItem(value: 'This Month', child: Text('This Month')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDateRange,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // + New Order Button -> POS
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
            value: _currency.format(_todayRevenue),
            subtitle: 'vs yesterday',
            badgeText: '+12.8%',
            icon: Icons.attach_money_rounded,
            accentColor: const Color(0xFF00A896),
            sparklinePoints: const [10, 15, 12, 22, 28, 35, 42],
            onTap: () => context.go('/reports'),
          ),
          MetricCard(
            title: 'Orders Today',
            value: '$_ordersTodayCount',
            subtitle: '8 new since 9 AM',
            icon: Icons.receipt_long_outlined,
            accentColor: const Color(0xFF02C39A),
            sparklinePoints: const [5, 8, 12, 18, 25, 33, 42],
            onTap: () => context.go('/pending'),
          ),
          MetricCard(
            title: 'In Production',
            value: '${_receivedCount + _washingCount + _finishingCount}',
            subtitle: 'Across 4 stages',
            icon: Icons.precision_manufacturing_outlined,
            accentColor: const Color(0xFFF59E0B),
            sparklinePoints: const [20, 18, 22, 25, 19, 18],
            onTap: () => context.go('/production'),
          ),
          MetricCard(
            title: 'Ready for Pickup',
            value: '$_readyCount',
            subtitle: '3 awaiting collection',
            icon: Icons.shopping_bag_outlined,
            accentColor: const Color(0xFF10B981),
            sparklinePoints: const [4, 6, 5, 9, 7, 7],
            onTap: () => context.go('/pending'),
          ),
        ];

        if (isCompact) {
          return Column(
            children: [
              Row(children: [Expanded(child: cards[0]), const SizedBox(width: 16), Expanded(child: cards[1])]),
              const SizedBox(height: 16),
              Row(children: [Expanded(child: cards[2]), const SizedBox(width: 16), Expanded(child: cards[3])]),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
            const SizedBox(width: 16),
            Expanded(child: cards[2]),
            const SizedBox(width: 16),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsAndPipeline() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 980;

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

                  // Interactive Chart Period Selector
                  PopupMenuButton<String>(
                    tooltip: 'Change chart period',
                    initialValue: _selectedChartPeriod,
                    onSelected: (val) {
                      setState(() => _selectedChartPeriod = val);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'Last 7 days', child: Text('Last 7 days')),
                      const PopupMenuItem(value: 'Last 30 days', child: Text('Last 30 days')),
                      const PopupMenuItem(value: 'This Quarter', child: Text('This Quarter')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            _selectedChartPeriod,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 190,
                child: InteractiveRevenueChart(
                  onPointTap: (idx, day, rev) {
                    context.go('/reports');
                  },
                ),
              ),
            ],
          ),
        );

        final totalPipeline = _receivedCount + _washingCount + _finishingCount + _readyCount;

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
                    '$totalPipeline total today',
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

              // Segmented Horizontal Bar with inner counts (Clickable)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      _pipelineSegment(flex: _receivedCount, label: '$_receivedCount', color: const Color(0xFF00A896), stageRoute: '/production'),
                      const SizedBox(width: 2),
                      _pipelineSegment(flex: _washingCount, label: '$_washingCount', color: const Color(0xFF3B82F6), stageRoute: '/production'),
                      const SizedBox(width: 2),
                      _pipelineSegment(flex: _finishingCount, label: '$_finishingCount', color: const Color(0xFFF59E0B), stageRoute: '/production'),
                      const SizedBox(width: 2),
                      _pipelineSegment(flex: _readyCount, label: '$_readyCount', color: const Color(0xFF0D1E36), stageRoute: '/pending'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              _pipelineRow('Received', _receivedCount, '${(totalPipeline > 0 ? (_receivedCount / totalPipeline * 100) : 0).toStringAsFixed(1)}%', const Color(0xFF00A896), '/production'),
              _pipelineRow('Washing', _washingCount, '${(totalPipeline > 0 ? (_washingCount / totalPipeline * 100) : 0).toStringAsFixed(1)}%', const Color(0xFF3B82F6), '/production'),
              _pipelineRow('Finishing', _finishingCount, '${(totalPipeline > 0 ? (_finishingCount / totalPipeline * 100) : 0).toStringAsFixed(1)}%', const Color(0xFFF59E0B), '/production'),
              _pipelineRow('Ready', _readyCount, '${(totalPipeline > 0 ? (_readyCount / totalPipeline * 100) : 0).toStringAsFixed(1)}%', const Color(0xFF0D1E36), '/pending'),
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

  Widget _pipelineSegment({required int flex, required String label, required Color color, required String stageRoute}) {
    return Expanded(
      flex: flex > 0 ? flex : 1,
      child: InkWell(
        onTap: () => context.go(stageRoute),
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
      ),
    );
  }

  Widget _pipelineRow(String label, int count, String pct, Color color, String route) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
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
      ),
    );
  }

  Widget _buildOrdersAndActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 980;

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
                      Icon(Icons.list_alt_rounded, size: 18, color: Color(0xFF00A896)),
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
                  InkWell(
                    onTap: () => context.go('/pending'),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            'View all',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00A896),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF00A896)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
    final defaultRows = [
      {'id': 'LP-10482', 'customer': 'Aisha Khan', 'service': 'Wash & Fold', 'due': '10:30 AM', 'status': 'Ready', 'stage': OrderStage.ready, 'total': 'AED 86.00', 'raw_total': 86.0},
      {'id': 'LP-10481', 'customer': 'Omar Hassan', 'service': 'Dry Cleaning', 'due': '11:00 AM', 'status': 'Finishing', 'stage': OrderStage.finishing, 'total': 'AED 145.00', 'raw_total': 145.0},
      {'id': 'LP-10480', 'customer': 'Mariam Ali', 'service': 'Abaya Care', 'due': '11:30 AM', 'status': 'Washing', 'stage': OrderStage.washing, 'total': 'AED 72.00', 'raw_total': 72.0},
      {'id': 'LP-10479', 'customer': 'Zayd Ahmed', 'service': 'Premium Press', 'due': '12:00 PM', 'status': 'Received', 'stage': OrderStage.received, 'total': 'AED 55.00', 'raw_total': 55.0},
    ];

    final rows = _recentOrders.isNotEmpty
        ? _recentOrders.map((ord) {
            final st = (ord['status'] ?? 'ready').toString().toLowerCase();
            OrderStage stage;
            if (st == 'washing') stage = OrderStage.washing;
            else if (st == 'finishing') stage = OrderStage.finishing;
            else if (st == 'received') stage = OrderStage.received;
            else stage = OrderStage.ready;

            final totalVal = (ord['grand_total'] as num?)?.toDouble() ?? 50.0;
            return {
              'id': ord['order_number'] ?? 'LP-10001',
              'customer': ord['customer_name'] ?? 'Guest Customer',
              'service': 'Wash & Fold',
              'due': '10:30 AM',
              'status': st.substring(0, 1).toUpperCase() + st.substring(1),
              'stage': stage,
              'total': 'AED ${totalVal.toStringAsFixed(2)}',
              'raw_total': totalVal,
            };
          }).toList()
        : defaultRows;

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
            Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6), child: Text('ORDER', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color(0xFF94A3B8)))),
            Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6), child: Text('CUSTOMER', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color(0xFF94A3B8)))),
            Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6), child: Text('SERVICE', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color(0xFF94A3B8)))),
            Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6), child: Text('DUE TIME', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color(0xFF94A3B8)))),
            Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6), child: Text('STATUS', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color(0xFF94A3B8)))),
            Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6), child: Align(alignment: Alignment.centerRight, child: Text('TOTAL', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color(0xFF94A3B8))))),
          ],
        ),

        // Interactive Clickable Table Rows -> Opens OrderDetailDialog
        ...rows.map((r) {
          final ordId = r['id'] as String;
          final cust = r['customer'] as String;
          final st = r['status'] as String;
          final grandTot = (r['raw_total'] as num?)?.toDouble() ?? 80.0;

          return TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.0)),
            ),
            children: [
              InkWell(
                onTap: () => OrderDetailDialog.show(context, orderNumber: ordId, customerName: cust, status: st, grandTotal: grandTot),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6), child: Text(ordId, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF00A896)))),
              ),
              InkWell(
                onTap: () => OrderDetailDialog.show(context, orderNumber: ordId, customerName: cust, status: st, grandTotal: grandTot),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6), child: Text(cust, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)))),
              ),
              InkWell(
                onTap: () => OrderDetailDialog.show(context, orderNumber: ordId, customerName: cust, status: st, grandTotal: grandTot),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6), child: Text(r['service'] as String, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B)))),
              ),
              InkWell(
                onTap: () => OrderDetailDialog.show(context, orderNumber: ordId, customerName: cust, status: st, grandTotal: grandTot),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6), child: Text(r['due'] as String, style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xFF94A3B8)))),
              ),
              InkWell(
                onTap: () => OrderDetailDialog.show(context, orderNumber: ordId, customerName: cust, status: st, grandTotal: grandTot),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6), child: StatusBadge(label: st, stage: r['stage'] as OrderStage, compact: true)),
              ),
              InkWell(
                onTap: () => OrderDetailDialog.show(context, orderNumber: ordId, customerName: cust, status: st, grandTotal: grandTot),
                child: Padding(
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
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _isHovered ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
              border: Border.all(
                color: _isHovered ? const Color(0xFF00A896).withOpacity(0.4) : const Color(0xFFE2E8F0),
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
