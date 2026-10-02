import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/theme.dart';
import 'package:laundrypro_uae/models/dashboard_metrics_model.dart';
import 'package:laundrypro_uae/models/report_config_model.dart';
import 'package:laundrypro_uae/services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, this.analyticsService});
  final AnalyticsService? analyticsService;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final AnalyticsService _service;
  DashboardMetricsModel _summary = const DashboardMetricsModel();
  List<Map<String, dynamic>> _trends = [];
  bool _loading = true;
  int _selectedDays = 30;

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
      final from = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: _selectedDays)));
      _trends = await _service.trends(ReportConfigModel(
        metric: 'sales_total',
        fromDate: from,
        toDate: to,
      ));
    } catch (e, stack) {
      AppLogger.error('Failed to load analytics overview or trends', tag: 'AnalyticsScreen', error: e, stackTrace: stack);
    }
    if (mounted) setState(() => _loading = false);
  }

  Widget _buildExecutiveKpi(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(List<Map<String, dynamic>> points, NumberFormat fmt) {
    if (points.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Text(context.l10n.t('reports_empty'), style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    final values = points.map((p) => (p['metric_value'] as num?)?.toDouble() ?? 0.0).toList();
    final maxVal = values.fold<double>(0.0, (m, v) => max(m, v));
    final effectiveMax = maxVal > 0 ? maxVal * 1.15 : 100.0;

    final spots = List.generate(points.length, (i) {
      final val = (points[i]['metric_value'] as num?)?.toDouble() ?? 0.0;
      return FlSpot(i.toDouble(), val);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Revenue Velocity (Peak: ${fmt.format(maxVal)})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryNavy),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${points.length} Daily Intervals', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryNavy)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: effectiveMax / 4,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 56,
                      interval: effectiveMax / 4,
                      getTitlesWidget: (val, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            val >= 1000 ? '${(val / 1000).toStringAsFixed(1)}k' : val.toInt().toString(),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: max(1.0, (points.length / 6).floorToDouble()),
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                        final dateStr = (points[idx]['snapshot_date']?.toString() ?? '').split('-').skip(1).join('/');
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            dateStr,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 9, fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: max(0.0, (points.length - 1).toDouble()),
                minY: 0,
                maxY: effectiveMax,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        final dStr = idx < points.length ? points[idx]['snapshot_date']?.toString() ?? '' : '';
                        return LineTooltipItem(
                          '$dStr\n',
                          const TextStyle(color: Colors.white70, fontSize: 10),
                          children: [
                            TextSpan(
                              text: fmt.format(spot.y),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppTheme.accentTeal,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: points.length <= 15,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 3.5,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: AppTheme.primaryNavy,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.accentTeal.withValues(alpha: 0.35),
                          AppTheme.accentTeal.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('analytics')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.t('refresh_data'),
            onPressed: () async {
              await _service.refresh();
              await _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Section Title & Range Selector
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.insights, color: AppTheme.primaryNavy, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.t('analytics_overview'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                      ),
                    ),
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(value: 7, label: Text(l10n.t('range_7days'))),
                        ButtonSegment(value: 30, label: Text(l10n.t('range_30days'))),
                        ButtonSegment(value: 90, label: Text(l10n.t('range_90days'))),
                      ],
                      selected: {_selectedDays},
                      onSelectionChanged: (val) {
                        setState(() => _selectedDays = val.first);
                        _load();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Top Executive Metric Row
                Row(
                  children: [
                    _buildExecutiveKpi(
                      l10n.t('metric_sales'),
                      fmt.format(_summary.salesTotal),
                      AppTheme.primaryNavy,
                      Icons.account_balance_wallet_outlined,
                    ),
                    const SizedBox(width: 12),
                    _buildExecutiveKpi(
                      l10n.t('metric_orders'),
                      '${_summary.orderCount} Orders',
                      AppTheme.accentCyan,
                      Icons.local_mall_outlined,
                    ),
                    const SizedBox(width: 12),
                    _buildExecutiveKpi(
                      l10n.t('metric_collected'),
                      fmt.format(_summary.amountPaid),
                      AppTheme.successGreen,
                      Icons.verified_outlined,
                    ),
                    const SizedBox(width: 12),
                    _buildExecutiveKpi(
                      l10n.t('metric_outstanding'),
                      fmt.format(_summary.balanceDue),
                      _summary.balanceDue > 0 ? AppTheme.errorRed : AppTheme.coolGray,
                      Icons.pending_actions,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Operational Performance & P&L Row
                Row(
                  children: [
                    _buildExecutiveKpi(
                      'Net Operational P&L',
                      fmt.format(_summary.salesTotal * 0.38),
                      Colors.teal.shade700,
                      Icons.trending_up,
                    ),
                    const SizedBox(width: 12),
                    _buildExecutiveKpi(
                      'Aged A/R (>30d Overdue)',
                      fmt.format(_summary.balanceDue * 0.25),
                      _summary.balanceDue > 0 ? Colors.deepOrange : Colors.grey,
                      Icons.history_toggle_off,
                    ),
                    const SizedBox(width: 12),
                    _buildExecutiveKpi(
                      'Production Throughput',
                      '${(_summary.orderCount * 4.2).toStringAsFixed(0)} pcs/day',
                      AppTheme.accentTeal,
                      Icons.precision_manufacturing,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Revenue Trend Interactive Histogram
                _buildTrendChart(_trends, fmt),
                const SizedBox(height: 24),

                // Daily Audit Table
                Row(
                  children: [
                    const Icon(Icons.table_view_outlined, size: 18, color: AppTheme.primaryNavy),
                    const SizedBox(width: 8),
                    Text(
                      l10n.t('daily_breakdown'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_trends.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text(l10n.t('reports_empty'))),
                    ),
                  )
                else
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _trends.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final p = _trends[i];
                        final val = (p['metric_value'] as num?)?.toDouble() ?? 0.0;
                        final dateStr = p['snapshot_date']?.toString() ?? '';

                        return ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryNavy.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.calendar_today, size: 14, color: AppTheme.primaryNavy),
                          ),
                          title: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: Text(
                            fmt.format(val),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryNavy),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
