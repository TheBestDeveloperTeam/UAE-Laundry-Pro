import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/theme.dart';
import 'package:laundrypro_uae/models/payroll_model.dart';
import 'package:laundrypro_uae/services/payroll_service.dart';
import 'package:laundrypro_uae/widgets/app_data_table.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key, this.payrollService});

  final PayrollService? payrollService;

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> with SingleTickerProviderStateMixin {
  late final PayrollService _payroll;
  late final TabController _tabController;

  List<PayrollModel> _periods = [];
  List<PayrollRunModel> _runs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _payroll = widget.payrollService ?? PayrollService();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _payroll.listPeriods(),
        _payroll.listPayrollRuns(),
      ]);
      _periods = results[0] as List<PayrollModel>;
      _runs = results[1] as List<PayrollRunModel>;
    } catch (e, stack) {
      AppLogger.error('Failed to load payroll periods or runs', tag: 'PayrollScreen', error: e, stackTrace: stack);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createPeriod() async {
    final l10n = context.l10n;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    final startController = TextEditingController(text: start.toIso8601String().split('T').first);
    final endController = TextEditingController(text: end.toIso8601String().split('T').first);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('payroll_period_create')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startController,
              decoration: InputDecoration(
                labelText: l10n.t('start_date'),
                prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: endController,
              decoration: InputDecoration(
                labelText: l10n.t('end_date'),
                prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.t('pos_close'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryNavy),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('save')),
          ),
        ],
      ),
    );

    if (ok != true) return;
    setState(() => _loading = true);
    try {
      await _payroll.createPeriod({
        'period_start': startController.text.trim(),
        'period_end': endController.text.trim(),
      });
    } catch (e, stack) {
      AppLogger.error('Failed to create payroll period', tag: 'PayrollScreen', error: e, stackTrace: stack);
    }
    await _load();
  }

  Future<void> _runPayroll(int periodId) async {
    setState(() => _loading = true);
    try {
      await _payroll.runPayroll(periodId);
      _tabController.animateTo(1);
    } catch (e, stack) {
      AppLogger.error('Failed to run payroll for period $periodId', tag: 'PayrollScreen', error: e, stackTrace: stack);
    }
    await _load();
  }

  void _showRunDetails(PayrollRunModel run) {
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (ctx, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.receipt_long, color: AppTheme.primaryNavy, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.t('payroll_run_details')} - ${run.runNo}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                            ),
                            Text(
                              '${run.periodStart.toIso8601String().split('T').first} → ${run.periodEnd.toIso8601String().split('T').first}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.accentGreen),
                        onPressed: () {
                          final sif = _payroll.generateWpsSif(run);
                          Clipboard.setData(ClipboardData(text: sif));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${l10n.t('wps_sif_downloaded')} (Copied to Clipboard)'),
                              backgroundColor: AppTheme.primaryNavy,
                            ),
                          );
                        },
                        icon: const Icon(Icons.download, size: 16, color: AppTheme.primaryNavy),
                        label: Text(
                          l10n.t('wps_sif_export'),
                          style: const TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(height: 24),

                  // Header metrics
                  Row(
                    children: [
                      _buildMiniKpi('Employees', '${run.lines.length}', AppTheme.primaryNavy),
                      const SizedBox(width: 12),
                      _buildMiniKpi(l10n.t('total_net_pay'), 'AED ${run.totalAmount.toStringAsFixed(2)}', AppTheme.successGreen),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    l10n.t('line_items'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryNavyLight),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: run.lines.isEmpty
                        ? const Center(child: Text('No breakdown lines available for this run'))
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: run.lines.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final line = run.lines[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryNavy.withValues(alpha: 0.08),
                                  child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
                                ),
                                title: Text(line.employeeName ?? 'Employee #${line.employeeId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Base: AED ${line.baseSalary.toStringAsFixed(2)} | Advance Deducted: AED ${line.advanceDeduction.toStringAsFixed(2)}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Net Salary', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    Text(
                                      'AED ${line.netPay.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMiniKpi(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('payroll')),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppTheme.accentCyan,
          indicatorWeight: 3,
          tabs: [
            Tab(icon: const Icon(Icons.date_range), text: l10n.t('period_range')),
            Tab(icon: const Icon(Icons.payments_outlined), text: l10n.t('payroll_runs')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.money_off_csred_outlined),
            tooltip: l10n.t('salary_advances'),
            onPressed: () => context.push('/hr/salary-advances'),
          ),
          IconButton(
            tooltip: l10n.t('refresh'),
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Payroll Periods
                _periods.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_month, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(l10n.t('payroll_empty'), style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : Card(
                        margin: const EdgeInsets.all(16),
                        clipBehavior: Clip.antiAlias,
                        child: AppDataTable(
                          columns: [
                            AppDataTableColumn(
                              label: 'Period Interval',
                              cellBuilder: (row) {
                                final s = row['period_start'] ?? '';
                                final e = row['period_end'] ?? '';
                                return Text('$s → $e', style: const TextStyle(fontWeight: FontWeight.bold));
                              },
                            ),
                            AppDataTableColumn(
                              label: l10n.t('status'),
                              key: 'status',
                              cellBuilder: (row) {
                                final isClosed = row['status'] == 'closed';
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isClosed ? AppTheme.coolGray : AppTheme.successGreen).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isClosed ? AppTheme.coolGray : AppTheme.successGreen),
                                  ),
                                  child: Text(
                                    (row['status'] ?? 'open').toString().toUpperCase(),
                                    style: TextStyle(
                                      color: isClosed ? AppTheme.coolGray : AppTheme.successGreen,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                            AppDataTableColumn(
                              label: l10n.t('actions'),
                              cellBuilder: (row) {
                                final isClosed = row['status'] == 'closed';
                                final id = row['id'] as int;
                                return isClosed
                                    ? const Text('Processed', style: TextStyle(color: Colors.grey))
                                    : FilledButton.icon(
                                        style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryNavy),
                                        onPressed: () => _runPayroll(id),
                                        icon: const Icon(Icons.play_arrow, size: 16),
                                        label: Text(l10n.t('payroll_run')),
                                      );
                              },
                            ),
                          ],
                          data: _periods.map((e) => e.toJson()).toList(),
                          isLoading: _loading,
                          emptyMessage: l10n.t('payroll_empty'),
                        ),
                      ),

                // Tab 2: Payroll Runs & WPS SIF Export
                _runs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('No payroll runs processed yet.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : Card(
                        margin: const EdgeInsets.all(16),
                        clipBehavior: Clip.antiAlias,
                        child: AppDataTable(
                          columns: [
                            AppDataTableColumn(
                              label: l10n.t('run_number'),
                              key: 'run_no',
                              cellBuilder: (row) => Text(
                                row['run_no'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                              ),
                            ),
                            AppDataTableColumn(
                              label: l10n.t('period_range'),
                              cellBuilder: (row) {
                                final s = row['period_start'] ?? '';
                                final e = row['period_end'] ?? '';
                                return Text('$s → $e');
                              },
                            ),
                            AppDataTableColumn(
                              label: l10n.t('total_net_pay'),
                              cellBuilder: (row) {
                                final amt = (row['total_amount'] as num?)?.toDouble() ?? 0.0;
                                return Text(
                                  'AED ${amt.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                                );
                              },
                            ),
                            AppDataTableColumn(
                              label: l10n.t('status'),
                              key: 'status',
                              cellBuilder: (row) => Text(
                                (row['status'] ?? 'POSTED').toString().toUpperCase(),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            AppDataTableColumn(
                              label: l10n.t('actions'),
                              cellBuilder: (row) {
                                final run = _runs.firstWhere((r) => r.id == row['id']);
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        side: const BorderSide(color: AppTheme.primaryNavy),
                                      ),
                                      onPressed: () => _showRunDetails(run),
                                      icon: const Icon(Icons.visibility, size: 14),
                                      label: const Text('View', style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.download_rounded, color: AppTheme.accentGreen),
                                      tooltip: l10n.t('wps_sif_export'),
                                      onPressed: () {
                                        final sif = _payroll.generateWpsSif(run);
                                        Clipboard.setData(ClipboardData(text: sif));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${l10n.t('wps_sif_downloaded')} (Copied to Clipboard)'),
                                            backgroundColor: AppTheme.primaryNavy,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                          data: _runs.map((r) => r.toJson()).toList(),
                          isLoading: _loading,
                          emptyMessage: 'No runs found',
                          onRowTap: (row) {
                            final run = _runs.firstWhere((r) => r.id == row['id']);
                            _showRunDetails(run);
                          },
                        ),
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        onPressed: _createPeriod,
        icon: const Icon(Icons.add),
        label: Text(l10n.t('payroll_period_create')),
      ),
    );
  }
}
