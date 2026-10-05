import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/theme.dart';
import 'package:laundrypro_uae/models/employee_model.dart';
import 'package:laundrypro_uae/models/salary_advance_model.dart';
import 'package:laundrypro_uae/services/employee_service.dart';
import 'package:laundrypro_uae/services/payroll_service.dart';
import 'package:laundrypro_uae/widgets/app_data_table.dart';

class SalaryAdvancesScreen extends StatefulWidget {
  const SalaryAdvancesScreen({super.key, this.payrollService, this.employeeService});

  final PayrollService? payrollService;
  final EmployeeService? employeeService;

  @override
  State<SalaryAdvancesScreen> createState() => _SalaryAdvancesScreenState();
}

class _SalaryAdvancesScreenState extends State<SalaryAdvancesScreen> {
  late final PayrollService _payroll;
  late final EmployeeService _employeeService;

  List<SalaryAdvanceModel> _items = [];
  List<EmployeeModel> _employees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _payroll = widget.payrollService ?? PayrollService();
    _employeeService = widget.employeeService ?? EmployeeService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _payroll.listSalaryAdvances(),
        _employeeService.list(),
      ]);
      _items = results[0] as List<SalaryAdvanceModel>;
      _employees = results[1] as List<EmployeeModel>;
    } catch (e, stack) {
      AppLogger.error('Failed to load salary advances or employees', tag: 'SalaryAdvancesScreen', error: e, stackTrace: stack);
    }
    if (mounted) setState(() => _loading = false);
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color border;
    IconData icon;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'open':
        bg = AppTheme.warningOrange.withValues(alpha: 0.12);
        border = AppTheme.warningOrange;
        icon = Icons.hourglass_bottom;
        break;
      case 'recovered':
        bg = AppTheme.successGreen.withValues(alpha: 0.12);
        border = AppTheme.successGreen;
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        bg = AppTheme.errorRed.withValues(alpha: 0.12);
        border = AppTheme.errorRed;
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = AppTheme.coolGray.withValues(alpha: 0.15);
        border = AppTheme.coolGray;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: border),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: border, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    final l10n = context.l10n;
    int? selectedEmpId = _employees.isNotEmpty ? _employees.first.id : null;
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final selectedEmp = _employees.firstWhere(
            (e) => e.id == selectedEmpId,
            orElse: () => _employees.first,
          );
          final maxAllowedAdvance = selectedEmp.baseSalary > 0 ? selectedEmp.baseSalary * 0.5 : 0.0;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.request_quote_outlined, color: AppTheme.primaryNavy, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.t('salary_advance_create'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          icon: const Icon(Icons.close),
                          splashRadius: 18,
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Employee selection
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: l10n.t('employees'),
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                      ),
                      items: _employees.map((e) {
                        return DropdownMenuItem<int>(
                          value: e.id,
                          child: Text('${e.fullName} (${e.employeeNo})'),
                        );
                      }).toList(),
                      initialValue: selectedEmpId,
                      onChanged: (val) => setDialogState(() => selectedEmpId = val),
                    ),
                    const SizedBox(height: 10),

                    // Employee salary context card
                    if (selectedEmp.baseSalary > 0)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNavy.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Base Salary: AED ${selectedEmp.baseSalary.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Max 50% Policy: AED ${maxAllowedAdvance.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryNavyLight),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: '${l10n.t('salary_advance_amount')} *',
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val <= 0) return 'Enter a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Reason / Notes',
                        prefixIcon: Icon(Icons.notes, size: 18),
                      ),
                      maxLines: 2,
                    ),
                    const Divider(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l10n.t('pos_close')),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryNavy),
                          onPressed: () {
                            if (formKey.currentState?.validate() ?? false) {
                              Navigator.pop(ctx, true);
                            }
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(l10n.t('save')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (saved != true || selectedEmpId == null) return;

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _loading = true);
    try {
      await _payroll.createSalaryAdvance({
        'employee_id': selectedEmpId,
        'amount': amount,
        if (notesController.text.isNotEmpty) 'notes': notesController.text.trim(),
      });
    } catch (e, stack) {
      AppLogger.error('Failed to create salary advance', tag: 'SalaryAdvancesScreen', error: e, stackTrace: stack);
    }
    await _load();
  }

  Widget _buildMiniKpi(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final openAdvances = _items.where((a) => a.status.toLowerCase() == 'open').toList();
    final totalOutstanding = openAdvances.fold<double>(0.0, (sum, a) => sum + a.currentBalance);
    final totalRecovered = _items.where((a) => a.status.toLowerCase() == 'recovered').fold<double>(0.0, (sum, a) => sum + a.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('salary_advances')),
        actions: [
          IconButton(
            tooltip: l10n.t('refresh'),
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // KPI Metric cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildMiniKpi(
                  'Outstanding Balance',
                  'AED ${totalOutstanding.toStringAsFixed(2)}',
                  AppTheme.warningOrange,
                  Icons.pending_actions,
                ),
                const SizedBox(width: 12),
                _buildMiniKpi(
                  'Recovered via Payroll',
                  'AED ${totalRecovered.toStringAsFixed(2)}',
                  AppTheme.successGreen,
                  Icons.task_alt,
                ),
                const SizedBox(width: 12),
                _buildMiniKpi(
                  'Active Advances',
                  '${openAdvances.length}',
                  AppTheme.primaryNavy,
                  Icons.receipt_outlined,
                ),
              ],
            ),
          ),

          // Advances Data Table
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.money_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(l10n.t('empty_data'), style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        clipBehavior: Clip.antiAlias,
                        child: AppDataTable(
                          columns: [
                            AppDataTableColumn(
                              label: l10n.t('employee_code'),
                              key: 'employee_no',
                              cellBuilder: (row) => Text(
                                row['employee_no'] ?? 'EMP-${row['employee_id']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                              ),
                            ),
                            AppDataTableColumn(
                              label: l10n.t('full_name'),
                              key: 'employee_name',
                              cellBuilder: (row) => Text(
                                row['employee_name'] ?? 'Employee #${row['employee_id']}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            AppDataTableColumn(
                              label: 'Advance Issued',
                              cellBuilder: (row) {
                                final amt = (row['amount'] as num?)?.toDouble() ?? 0.0;
                                return Text('AED ${amt.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold));
                              },
                            ),
                            AppDataTableColumn(
                              label: l10n.t('remaining_balance'),
                              cellBuilder: (row) {
                                final bal = (row['balance_remaining'] as num?)?.toDouble() ?? ((row['amount'] as num?)?.toDouble() ?? 0.0);
                                final isRecovered = bal <= 0;
                                return Text(
                                  'AED ${bal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isRecovered ? AppTheme.successGreen : AppTheme.errorRed,
                                  ),
                                );
                              },
                            ),
                            const AppDataTableColumn(
                              label: 'Date',
                              key: 'request_date',
                            ),
                            AppDataTableColumn(
                              label: 'Notes',
                              key: 'notes',
                              cellBuilder: (row) => Text(row['notes'] ?? row['reason'] ?? '-', style: TextStyle(color: Colors.grey.shade600)),
                            ),
                            AppDataTableColumn(
                              label: l10n.t('status'),
                              key: 'status',
                              cellBuilder: (row) => _buildStatusBadge((row['status'] ?? 'open').toString()),
                            ),
                          ],
                          data: _items.map((a) => a.toJson()).toList(),
                          isLoading: _loading,
                          emptyMessage: l10n.t('empty_data'),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        onPressed: _openCreateDialog,
        icon: const Icon(Icons.add),
        label: Text(l10n.t('salary_advance_create')),
      ),
    );
  }
}
