import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/theme.dart';
import 'package:laundrypro_uae/models/employee_model.dart';
import 'package:laundrypro_uae/services/employee_service.dart';
import 'package:laundrypro_uae/widgets/app_data_table.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key, this.employeeService});

  final EmployeeService? employeeService;

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  late final EmployeeService _employees;
  final _searchController = TextEditingController();
  List<EmployeeModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _employees = widget.employeeService ?? EmployeeService();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _employees.list(query: _searchController.text.trim());
    } catch (e, stack) {
      AppLogger.error('Failed to load employees list', tag: 'EmployeesScreen', error: e, stackTrace: stack);
    }
    if (mounted) setState(() => _loading = false);
  }

  bool _isExpiringSoon(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    return difference >= 0 && difference <= 30;
  }

  bool _isExpired(DateTime? date) {
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }

  Widget _buildExpiryBadge(DateTime? date, String label) {
    if (date == null) {
      return Text('-', style: TextStyle(color: Colors.grey.shade500));
    }
    final formatted = date.toIso8601String().split('T').first;
    if (_isExpired(date)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 12, color: AppTheme.errorRed),
            const SizedBox(width: 4),
            Text(formatted, style: const TextStyle(color: AppTheme.errorRed, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    if (_isExpiringSoon(date)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.warningOrange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 12, color: AppTheme.warningOrange),
            const SizedBox(width: 4),
            Text(formatted, style: const TextStyle(color: AppTheme.warningOrange, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    return Text(formatted, style: const TextStyle(fontSize: 12));
  }

  Widget _buildStatusBadge(bool isActive, String status, BuildContext context) {
    final l10n = context.l10n;
    Color color = AppTheme.successGreen;
    String text = l10n.t('status_active');

    if (!isActive || status == 'terminated') {
      color = AppTheme.errorRed;
      text = l10n.t('status_terminated');
    } else if (status == 'on_leave') {
      color = AppTheme.warningOrange;
      text = l10n.t('status_on_leave');
    } else if (status == 'inactive') {
      color = AppTheme.coolGray;
      text = l10n.t('status_inactive');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _openEmployeeDialog({EmployeeModel? employee}) async {
    final l10n = context.l10n;
    final isEdit = employee != null;

    final nameController = TextEditingController(text: employee?.fullName ?? '');
    final phoneController = TextEditingController(text: employee?.phone ?? '');
    final emailController = TextEditingController(text: employee?.email ?? '');
    final titleController = TextEditingController(text: employee?.jobTitle ?? '');
    final deptController = TextEditingController(text: employee?.department ?? '');
    final salaryController = TextEditingController(
      text: employee != null && employee.baseSalary > 0 ? employee.baseSalary.toStringAsFixed(2) : '',
    );
    final civilIdController = TextEditingController(text: employee?.civilId ?? '');
    final passportController = TextEditingController(text: employee?.passportNo ?? '');
    final pinController = TextEditingController(text: employee?.pin ?? '');

    DateTime? civilIdExp = employee?.civilIdExpiry;
    DateTime? visaExp = employee?.visaExpiry;

    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            width: 650,
            constraints: const BoxConstraints(maxHeight: 700),
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
                          color: AppTheme.primaryNavy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.badge_outlined, color: AppTheme.primaryNavy, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEdit ? l10n.t('employee_edit') : l10n.t('employee_create'),
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Personal Information
                          Text(
                            l10n.t('employee_details'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryNavyLight),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    labelText: '${l10n.t('full_name')} *',
                                    prefixIcon: const Icon(Icons.person_outline, size: 18),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? l10n.t('name') : null,
                                  autofocus: !isEdit,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: pinController,
                                  decoration: const InputDecoration(
                                    labelText: 'PIN (Clock-In)',
                                    prefixIcon: Icon(Icons.lock_outline, size: 18),
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: phoneController,
                                  decoration: InputDecoration(
                                    labelText: l10n.t('phone'),
                                    prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: emailController,
                                  decoration: InputDecoration(
                                    labelText: l10n.t('email'),
                                    prefixIcon: const Icon(Icons.email_outlined, size: 18),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Job & Department
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: titleController,
                                  decoration: InputDecoration(
                                    labelText: l10n.t('job_title'),
                                    prefixIcon: const Icon(Icons.work_outline, size: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: deptController,
                                  decoration: InputDecoration(
                                    labelText: l10n.t('department'),
                                    prefixIcon: const Icon(Icons.business_outlined, size: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: salaryController,
                                  decoration: InputDecoration(
                                    labelText: l10n.t('base_salary'),
                                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // UAE Legal / Compliance
                          const Divider(),
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 16, color: AppTheme.accentCyan),
                              SizedBox(width: 6),
                              Text(
                                'UAE Compliance & Passports',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryNavyLight),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: civilIdController,
                                  decoration: InputDecoration(
                                    labelText: l10n.t('emirates_id'),
                                    hintText: '784-XXXX-XXXXXXX-X',
                                    prefixIcon: const Icon(Icons.credit_card_outlined, size: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: () async {
                                    final now = DateTime.now();
                                    final picked = await showDatePicker(
                                      context: ctx,
                                      initialDate: civilIdExp ?? now.add(const Duration(days: 365)),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setDialogState(() => civilIdExp = picked);
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: l10n.t('emirates_id_expiry'),
                                      prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                                    ),
                                    child: Text(
                                      civilIdExp != null
                                          ? civilIdExp!.toIso8601String().split('T').first
                                          : 'Select Date',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: civilIdExp != null ? AppTheme.darkSlate : AppTheme.coolGray,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: passportController,
                                  decoration: InputDecoration(
                                    labelText: l10n.t('passport_number'),
                                    prefixIcon: const Icon(Icons.menu_book_outlined, size: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: () async {
                                    final now = DateTime.now();
                                    final picked = await showDatePicker(
                                      context: ctx,
                                      initialDate: visaExp ?? now.add(const Duration(days: 365)),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setDialogState(() => visaExp = picked);
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: l10n.t('visa_expiry'),
                                      prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
                                    ),
                                    child: Text(
                                      visaExp != null
                                          ? visaExp!.toIso8601String().split('T').first
                                          : 'Select Date',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: visaExp != null ? AppTheme.darkSlate : AppTheme.coolGray,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.t('pos_close')),
                      ),
                      const SizedBox(width: 12),
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
        ),
      ),
    );

    if (saved != true) return;

    final body = <String, dynamic>{
      'full_name': nameController.text.trim(),
      if (phoneController.text.isNotEmpty) 'phone': phoneController.text.trim(),
      if (emailController.text.isNotEmpty) 'email': emailController.text.trim(),
      if (titleController.text.isNotEmpty) 'job_title': titleController.text.trim(),
      if (deptController.text.isNotEmpty) 'department': deptController.text.trim(),
      'base_salary': double.tryParse(salaryController.text.trim()) ?? 0.0,
      if (civilIdController.text.isNotEmpty) 'civil_id': civilIdController.text.trim(),
      if (civilIdExp != null) 'civil_id_expiry': civilIdExp!.toIso8601String().split('T').first,
      if (passportController.text.isNotEmpty) 'passport_no': passportController.text.trim(),
      if (visaExp != null) 'visa_expiry': visaExp!.toIso8601String().split('T').first,
      if (pinController.text.isNotEmpty) 'pin': pinController.text.trim(),
    };

    setState(() => _loading = true);
    try {
      if (isEdit) {
        await _employees.update(employee.id, body);
      } else {
        await _employees.create(body);
      }
    } catch (_) {}
    await _load();
  }

  Future<void> _confirmDeactivate(EmployeeModel emp) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('deactivate')),
        content: Text('${l10n.t('confirm_deactivate_employee')}\n\n${emp.fullName} (${emp.employeeNo})'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.t('pos_close'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('deactivate')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _employees.deactivate(emp.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final expiringCount = _items.where((e) => _isExpiringSoon(e.civilIdExpiry) || _isExpiringSoon(e.visaExpiry) || _isExpired(e.civilIdExpiry) || _isExpired(e.visaExpiry)).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('employees')),
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
          // Header banner & quick search
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '${l10n.t('search')} (${l10n.t('full_name')}, ${l10n.t('employee_code')}, ${l10n.t('phone')})...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _load();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onPressed: () => _openEmployeeDialog(),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: Text(l10n.t('employee_create')),
                ),
              ],
            ),
          ),

          // Compliance Alert Banner if any employee has documents expiring
          if (expiringCount > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$expiringCount employee document(s) expired or expiring within 30 days. Please review Emirates ID / Visa dates.',
                      style: const TextStyle(color: AppTheme.darkSlate, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.badge_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              l10n.t('employees_empty'),
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
                                row['employee_no'] ?? row['employee_id'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                              ),
                            ),
                            AppDataTableColumn(
                              label: l10n.t('full_name'),
                              key: 'full_name',
                              cellBuilder: (row) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(row['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (row['email'] != null && row['email'].toString().isNotEmpty)
                                    Text(row['email'], style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            AppDataTableColumn(
                              label: l10n.t('department'),
                              key: 'department',
                              cellBuilder: (row) => Text(row['department'] ?? '-'),
                            ),
                            AppDataTableColumn(
                              label: l10n.t('job_title'),
                              key: 'job_title',
                              cellBuilder: (row) => Text(row['job_title'] ?? row['position'] ?? '-'),
                            ),
                            AppDataTableColumn(
                              label: l10n.t('phone'),
                              key: 'phone',
                            ),
                            AppDataTableColumn(
                              label: l10n.t('emirates_id_expiry'),
                              cellBuilder: (row) {
                                final d = row['civil_id_expiry'] != null
                                    ? DateTime.tryParse(row['civil_id_expiry'].toString())
                                    : null;
                                return _buildExpiryBadge(d, 'Civil ID');
                              },
                            ),
                            AppDataTableColumn(
                              label: l10n.t('visa_expiry'),
                              cellBuilder: (row) {
                                final d = row['visa_expiry'] != null
                                    ? DateTime.tryParse(row['visa_expiry'].toString())
                                    : null;
                                return _buildExpiryBadge(d, 'Visa');
                              },
                            ),
                            AppDataTableColumn(
                              label: l10n.t('status'),
                              cellBuilder: (row) {
                                final isActive = row['is_active'] == 1 || row['is_active'] == true;
                                final status = row['status']?.toString() ?? 'active';
                                return _buildStatusBadge(isActive, status, context);
                              },
                            ),
                            AppDataTableColumn(
                              label: l10n.t('actions'),
                              cellBuilder: (row) {
                                final emp = _items.firstWhere((e) => e.id == row['id']);
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryNavy),
                                      tooltip: l10n.t('employee_edit'),
                                      onPressed: () => _openEmployeeDialog(employee: emp),
                                      splashRadius: 18,
                                    ),
                                    if (emp.isActive)
                                      IconButton(
                                        icon: const Icon(Icons.person_off_outlined, size: 18, color: AppTheme.errorRed),
                                        tooltip: l10n.t('deactivate'),
                                        onPressed: () => _confirmDeactivate(emp),
                                        splashRadius: 18,
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                          data: _items.map((e) => e.toJson()).toList(),
                          isLoading: _loading,
                          emptyMessage: l10n.t('employees_empty'),
                          onRowTap: (row) {
                            final emp = _items.firstWhere((e) => e.id == row['id']);
                            _openEmployeeDialog(employee: emp);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
