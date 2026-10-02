import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/theme.dart';
import 'package:laundrypro_uae/models/attendance_model.dart';
import 'package:laundrypro_uae/models/employee_model.dart';
import 'package:laundrypro_uae/services/attendance_service.dart';
import 'package:laundrypro_uae/services/employee_service.dart';
import 'package:laundrypro_uae/widgets/app_data_table.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, this.attendanceService, this.employeeService});

  final AttendanceService? attendanceService;
  final EmployeeService? employeeService;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final AttendanceService _attendance;
  late final EmployeeService _employeeService;

  List<AttendanceModel> _items = [];
  List<EmployeeModel> _employees = [];
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _attendance = widget.attendanceService ?? AttendanceService();
    _employeeService = widget.employeeService ?? EmployeeService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final dateStr = _selectedDate.toIso8601String().split('T').first;
    try {
      final results = await Future.wait([
        _attendance.list(from: dateStr, to: dateStr),
        _employeeService.list(),
      ]);
      _items = results[0] as List<AttendanceModel>;
      _employees = results[1] as List<EmployeeModel>;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Widget _buildStatusBadge(String status, BuildContext context) {
    Color bg;
    Color border;
    IconData icon;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'present':
        bg = AppTheme.successGreen.withValues(alpha: 0.12);
        border = AppTheme.successGreen;
        icon = Icons.check_circle_outline;
        break;
      case 'absent':
        bg = AppTheme.errorRed.withValues(alpha: 0.12);
        border = AppTheme.errorRed;
        icon = Icons.cancel_outlined;
        break;
      case 'half_day':
        bg = AppTheme.warningOrange.withValues(alpha: 0.12);
        border = AppTheme.warningOrange;
        icon = Icons.timelapse;
        break;
      case 'leave':
        bg = AppTheme.infoBlue.withValues(alpha: 0.12);
        border = AppTheme.infoBlue;
        icon = Icons.beach_access_outlined;
        break;
      default:
        bg = AppTheme.coolGray.withValues(alpha: 0.15);
        border = AppTheme.coolGray;
        icon = Icons.help_outline;
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

  Future<void> _openClockInOutModal() async {
    final l10n = context.l10n;
    final pinOrCodeController = TextEditingController();
    String selectedStatus = 'present';
    int? selectedEmpId;
    final notesController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.alarm_on, color: AppTheme.primaryNavy, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.t('attendance_record'),
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

                  // Quick lookup by PIN / Barcode / Employee selection
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: l10n.t('employees'),
                      prefixIcon: const Icon(Icons.person_search, size: 20),
                    ),
                    items: _employees.map((e) {
                      return DropdownMenuItem<int>(
                        value: e.id,
                        child: Text('${e.fullName} (${e.employeeNo})'),
                      );
                    }).toList(),
                    initialValue: selectedEmpId,
                    onChanged: (val) {
                      setModalState(() {
                        selectedEmpId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: pinOrCodeController,
                          decoration: InputDecoration(
                            labelText: l10n.t('scan_badge_pin'),
                            hintText: 'PIN or Badge Scan',
                            prefixIcon: const Icon(Icons.qr_code_scanner, size: 20),
                          ),
                          onSubmitted: (val) {
                            final match = _employees.firstWhere(
                              (e) => (e.pin != null && e.pin == val.trim()) || e.employeeNo.toLowerCase() == val.trim().toLowerCase(),
                              orElse: () => _employees.isNotEmpty ? _employees.first : _employees.first,
                            );
                            if (match.id > 0) {
                              setModalState(() => selectedEmpId = match.id);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Shift status
                  Text(l10n.t('status'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryNavyLight)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['present', 'half_day', 'absent', 'leave'].map((st) {
                      final isSelected = selectedStatus == st;
                      return ChoiceChip(
                        label: Text(st.toUpperCase()),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setModalState(() => selectedStatus = st);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Remarks',
                      prefixIcon: Icon(Icons.note_alt_outlined, size: 18),
                    ),
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
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.accentGreen),
                        onPressed: selectedEmpId == null
                            ? null
                            : () => Navigator.pop(ctx, true),
                        icon: const Icon(Icons.check, size: 18, color: AppTheme.primaryNavy),
                        label: Text(l10n.t('save'), style: const TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (saved != true || selectedEmpId == null) return;

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    setState(() => _loading = true);
    try {
      await _attendance.record({
        'employee_id': selectedEmpId,
        'attendance_date': _selectedDate.toIso8601String().split('T').first,
        'status': selectedStatus,
        'check_in': selectedStatus == 'present' || selectedStatus == 'half_day' ? timeStr : null,
        if (notesController.text.isNotEmpty) 'notes': notesController.text.trim(),
      });
    } catch (_) {}
    await _load();
  }

  Future<void> _quickClockOut(AttendanceModel item) async {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    setState(() => _loading = true);
    try {
      await _attendance.record({
        'employee_id': item.employeeId,
        'attendance_date': item.date.toIso8601String().split('T').first,
        'status': item.status,
        'check_in': item.checkIn,
        'check_out': timeStr,
        'notes': item.notes,
      });
    } catch (_) {}
    await _load();
  }

  Widget _buildSummaryCard(String title, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
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

    final presentCount = _items.where((e) => e.status == 'present').length;
    final absentCount = _items.where((e) => e.status == 'absent').length;
    final halfDayCount = _items.where((e) => e.status == 'half_day').length;
    final leaveCount = _items.where((e) => e.status == 'leave').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('hr_attendance')),
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
          // Date navigation toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                    });
                    _load();
                  },
                ),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      _load();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryNavy),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDate.toIso8601String().split('T').first,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    });
                    _load();
                  },
                ),
                const Spacer(),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: _openClockInOutModal,
                  icon: const Icon(Icons.fingerprint, size: 20),
                  label: Text(l10n.t('attendance_record')),
                ),
              ],
            ),
          ),

          // Daily Attendance Headcount Metric Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildSummaryCard(l10n.t('total_present'), presentCount, AppTheme.successGreen, Icons.how_to_reg),
                const SizedBox(width: 12),
                _buildSummaryCard('Half Day', halfDayCount, AppTheme.warningOrange, Icons.timelapse),
                const SizedBox(width: 12),
                _buildSummaryCard(l10n.t('total_absent'), absentCount, AppTheme.errorRed, Icons.person_off_outlined),
                const SizedBox(width: 12),
                _buildSummaryCard(l10n.t('total_on_leave'), leaveCount, AppTheme.infoBlue, Icons.beach_access_outlined),
              ],
            ),
          ),

          // Attendance register table
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              l10n.t('attendance_empty'),
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
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
                              label: l10n.t('status'),
                              key: 'status',
                              cellBuilder: (row) => _buildStatusBadge(row['status'] ?? 'present', context),
                            ),
                            AppDataTableColumn(
                              label: l10n.t('clock_in'),
                              key: 'check_in',
                              cellBuilder: (row) => Text(
                                row['check_in'] != null && row['check_in'].toString().isNotEmpty
                                    ? row['check_in'].toString()
                                    : '--:--',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            AppDataTableColumn(
                              label: l10n.t('clock_out'),
                              key: 'check_out',
                              cellBuilder: (row) => Text(
                                row['check_out'] != null && row['check_out'].toString().isNotEmpty
                                    ? row['check_out'].toString()
                                    : '--:--',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            AppDataTableColumn(
                              label: 'Notes',
                              key: 'notes',
                              cellBuilder: (row) => Text(row['notes'] ?? '-', style: TextStyle(color: Colors.grey.shade600)),
                            ),
                            AppDataTableColumn(
                              label: l10n.t('actions'),
                              cellBuilder: (row) {
                                final att = _items.firstWhere((e) => e.id == row['id']);
                                final canClockOut = att.checkIn != null && (att.checkOut == null || att.checkOut!.isEmpty);
                                return canClockOut
                                    ? OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          foregroundColor: AppTheme.warningOrange,
                                          side: const BorderSide(color: AppTheme.warningOrange),
                                        ),
                                        onPressed: () => _quickClockOut(att),
                                        icon: const Icon(Icons.logout, size: 14),
                                        label: Text(l10n.t('clock_out'), style: const TextStyle(fontSize: 12)),
                                      )
                                    : const SizedBox.shrink();
                              },
                            ),
                          ],
                          data: _items.map((e) => e.toJson()).toList(),
                          isLoading: _loading,
                          emptyMessage: l10n.t('attendance_empty'),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
