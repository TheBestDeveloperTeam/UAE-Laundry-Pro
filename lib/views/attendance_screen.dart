import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, this.attendanceService});

  final AttendanceService? attendanceService;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final AttendanceService _attendance;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _attendance = widget.attendanceService ?? AttendanceService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _attendance.list();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _record() async {
    final l10n = context.l10n;
    final employeeController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('attendance_record')),
        content: TextField(
          controller: employeeController,
          decoration: InputDecoration(labelText: l10n.t('employee_id')),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.t('pos_close'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.t('save'))),
        ],
      ),
    );
    if (ok != true) return;
    final employeeId = int.tryParse(employeeController.text.trim());
    if (employeeId == null) return;
    await _attendance.record({
      'employee_id': employeeId,
      'attendance_date': DateTime.now().toIso8601String().split('T').first,
      'status': 'present',
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('attendance')),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(l10n.t('attendance_empty')))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final a = _items[i];
                    return ListTile(
                      title: Text('${l10n.t('employee_id')}: ${a['employee_id']}'),
                      subtitle: Text('${a['attendance_date']} · ${a['status']}'),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(onPressed: _record, child: const Icon(Icons.add)),
    );
  }
}
