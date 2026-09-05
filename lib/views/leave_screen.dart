import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/payroll_service.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key, this.payrollService});

  final PayrollService? payrollService;

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  late final PayrollService _payroll;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _payroll = widget.payrollService ?? PayrollService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _payroll.listLeave();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _create() async {
    final l10n = context.l10n;
    final employeeController = TextEditingController();
    final startController = TextEditingController(text: DateTime.now().toIso8601String().split('T').first);
    final endController = TextEditingController(text: DateTime.now().toIso8601String().split('T').first);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('leave_create')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: employeeController, decoration: InputDecoration(labelText: l10n.t('employee_id')), keyboardType: TextInputType.number),
            TextField(controller: startController, decoration: InputDecoration(labelText: l10n.t('start_date'))),
            TextField(controller: endController, decoration: InputDecoration(labelText: l10n.t('end_date'))),
          ],
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
    await _payroll.createLeave({
      'employee_id': employeeId,
      'start_date': startController.text.trim(),
      'end_date': endController.text.trim(),
      'leave_type_id': 1,
    });
    await _load();
  }

  Future<void> _approve(int id) async {
    await _payroll.approveLeave(id);
    await _load();
  }

  Future<void> _reject(int id) async {
    await _payroll.rejectLeave(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('leave')),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(l10n.t('leave_empty')))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final l = _items[i];
                    final id = int.tryParse(l['id']?.toString() ?? '');
                    return ListTile(
                      title: Text('${l10n.t('employee_id')}: ${l['employee_id']}'),
                      subtitle: Text('${l['start_date']} → ${l['end_date']} · ${l['status']}'),
                      trailing: l['status'] == 'pending' && id != null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.check), onPressed: () => _approve(id)),
                                IconButton(icon: const Icon(Icons.close), onPressed: () => _reject(id)),
                              ],
                            )
                          : null,
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(onPressed: _create, child: const Icon(Icons.add)),
    );
  }
}
