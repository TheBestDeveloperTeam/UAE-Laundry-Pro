import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/theme.dart';
import 'package:laundrypro_uae/models/employee_model.dart';
import 'package:laundrypro_uae/models/leave_model.dart';
import 'package:laundrypro_uae/services/employee_service.dart';
import 'package:laundrypro_uae/services/payroll_service.dart';
import 'package:laundrypro_uae/widgets/app_data_table.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key, this.payrollService, this.employeeService});

  final PayrollService? payrollService;
  final EmployeeService? employeeService;

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  late final PayrollService _payroll;
  late final EmployeeService _employeeService;

  List<LeaveModel> _items = [];
  List<EmployeeModel> _employees = [];
  List<Map<String, dynamic>> _leaveTypes = [];
  bool _loading = true;
  String _statusFilter = 'all';

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
        _payroll.listLeave(status: _statusFilter == 'all' ? null : _statusFilter),
        _employeeService.list(),
        _payroll.listLeaveTypes(),
      ]);
      _items = results[0] as List<LeaveModel>;
      _employees = results[1] as List<EmployeeModel>;
      _leaveTypes = results[2] as List<Map<String, dynamic>>;
    } catch (e, stack) {
      AppLogger.error('Failed to load leave requests or types', tag: 'LeaveScreen', error: e, stackTrace: stack);
    }
    if (mounted) setState(() => _loading = false);
  }

  Widget _buildStatusBadge(String status, BuildContext context) {
    Color bg;
    Color border;
    IconData icon;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'approved':
        bg = AppTheme.successGreen.withValues(alpha: 0.12);
        border = AppTheme.successGreen;
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        bg = AppTheme.errorRed.withValues(alpha: 0.12);
        border = AppTheme.errorRed;
        icon = Icons.cancel_outlined;
        break;
      case 'pending':
      default:
        bg = AppTheme.warningOrange.withValues(alpha: 0.12);
        border = AppTheme.warningOrange;
        icon = Icons.hourglass_top;
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

  Future<void> _openLeaveDialog() async {
    final l10n = context.l10n;
    int? selectedEmpId = _employees.isNotEmpty ? _employees.first.id : null;
    int? selectedTypeId = _leaveTypes.isNotEmpty ? (_leaveTypes.first['id'] as int?) : 1;

    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 2));
    final reasonController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final days = endDate.difference(startDate).inDays + 1;
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Container(
              width: 550,
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
                            color: AppTheme.infoBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.beach_access_outlined, color: AppTheme.infoBlue, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.t('leave_create'),
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

                    // Employee dropdown
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
                    const SizedBox(height: 14),

                    // Leave Type
                    if (_leaveTypes.isNotEmpty)
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Leave Type',
                          prefixIcon: Icon(Icons.category_outlined, size: 20),
                        ),
                        items: _leaveTypes.map((t) {
                          return DropdownMenuItem<int>(
                            value: t['id'] as int?,
                            child: Text(t['name']?.toString() ?? 'Leave'),
                          );
                        }).toList(),
                        initialValue: selectedTypeId,
                        onChanged: (val) => setDialogState(() => selectedTypeId = val),
                      ),
                    const SizedBox(height: 14),

                    // Date pickers row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: startDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  startDate = picked;
                                  if (endDate.isBefore(startDate)) {
                                    endDate = startDate;
                                  }
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: l10n.t('start_date'),
                                prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                              ),
                              child: Text(startDate.toIso8601String().split('T').first),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: endDate,
                                firstDate: startDate,
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setDialogState(() => endDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: l10n.t('end_date'),
                                prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
                              ),
                              child: Text(endDate.toIso8601String().split('T').first),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Duration indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Duration: $days Day(s)',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavyLight, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Reason for Leave',
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
                          onPressed: selectedEmpId == null
                              ? null
                              : () => Navigator.pop(ctx, true),
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

    setState(() => _loading = true);
    try {
      await _payroll.createLeave({
        'employee_id': selectedEmpId,
        'leave_type_id': selectedTypeId ?? 1,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate.toIso8601String().split('T').first,
        if (reasonController.text.isNotEmpty) 'reason': reasonController.text.trim(),
      });
    } catch (e, stack) {
      AppLogger.error('Failed to create leave request', tag: 'LeaveScreen', error: e, stackTrace: stack);
    }
    await _load();
  }

  Future<void> _handleApprove(int id) async {
    setState(() => _loading = true);
    try {
      await _payroll.approveLeave(id);
    } catch (e, stack) {
      AppLogger.error('Failed to approve leave request', tag: 'LeaveScreen', error: e, stackTrace: stack);
    }
    await _load();
  }

  Future<void> _handleReject(int id) async {
    setState(() => _loading = true);
    try {
      await _payroll.rejectLeave(id);
    } catch (e, stack) {
      AppLogger.error('Failed to reject leave request', tag: 'LeaveScreen', error: e, stackTrace: stack);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final pendingCount = _items.where((e) => e.status == 'pending').length;
    final approvedCount = _items.where((e) => e.status == 'approved').length;
    final rejectedCount = _items.where((e) => e.status == 'rejected').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('hr_leave_requests')),
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
          // Filter toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text('All (${_items.length})'),
                      selected: _statusFilter == 'all',
                      onSelected: (val) {
                        if (val) {
                          setState(() => _statusFilter = 'all');
                          _load();
                        }
                      },
                    ),
                    ChoiceChip(
                      label: Text('Pending ($pendingCount)'),
                      selected: _statusFilter == 'pending',
                      onSelected: (val) {
                        if (val) {
                          setState(() => _statusFilter = 'pending');
                          _load();
                        }
                      },
                    ),
                    ChoiceChip(
                      label: Text('Approved ($approvedCount)'),
                      selected: _statusFilter == 'approved',
                      onSelected: (val) {
                        if (val) {
                          setState(() => _statusFilter = 'approved');
                          _load();
                        }
                      },
                    ),
                    ChoiceChip(
                      label: Text('Rejected ($rejectedCount)'),
                      selected: _statusFilter == 'rejected',
                      onSelected: (val) {
                        if (val) {
                          setState(() => _statusFilter = 'rejected');
                          _load();
                        }
                      },
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: _openLeaveDialog,
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(l10n.t('leave_create')),
                ),
              ],
            ),
          ),

          // Leave Requests Table
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.beach_access_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              l10n.t('leave_empty'),
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : Card(
                        margin: const EdgeInsets.all(16),
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
                              label: 'Leave Type',
                              key: 'leave_type',
                              cellBuilder: (row) => Text(row['leave_type'] ?? 'Annual Leave'),
                            ),
                            AppDataTableColumn(
                              label: 'Period',
                              cellBuilder: (row) {
                                final start = row['start_date'] ?? '';
                                final end = row['end_date'] ?? '';
                                return Text('$start → $end');
                              },
                            ),
                            AppDataTableColumn(
                              label: 'Days',
                              cellBuilder: (row) {
                                final s = DateTime.tryParse(row['start_date']?.toString() ?? '');
                                final e = DateTime.tryParse(row['end_date']?.toString() ?? '');
                                final days = s != null && e != null ? e.difference(s).inDays + 1 : 1;
                                return Text('$days day(s)', style: const TextStyle(fontWeight: FontWeight.bold));
                              },
                            ),
                            AppDataTableColumn(
                              label: 'Reason',
                              key: 'reason',
                              cellBuilder: (row) => Text(row['reason'] ?? '-', style: TextStyle(color: Colors.grey.shade600)),
                            ),
                            AppDataTableColumn(
                              label: l10n.t('status'),
                              key: 'status',
                              cellBuilder: (row) => _buildStatusBadge(row['status'] ?? 'pending', context),
                            ),
                            AppDataTableColumn(
                              label: l10n.t('actions'),
                              cellBuilder: (row) {
                                final l = _items.firstWhere((item) => item.id == row['id']);
                                if (l.status == 'pending') {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 20),
                                        tooltip: 'Approve Leave',
                                        onPressed: () => _handleApprove(l.id),
                                        splashRadius: 18,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel_outlined, color: AppTheme.errorRed, size: 20),
                                        tooltip: 'Reject Leave',
                                        onPressed: () => _handleReject(l.id),
                                        splashRadius: 18,
                                      ),
                                    ],
                                  );
                                }
                                return Text(
                                  l.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: l.status == 'approved' ? AppTheme.successGreen : AppTheme.errorRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ],
                          data: _items.map((e) => e.toJson()).toList(),
                          isLoading: _loading,
                          emptyMessage: l10n.t('leave_empty'),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
