import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/payroll_service.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key, this.payrollService});

  final PayrollService? payrollService;

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  late final PayrollService _payroll;
  List<Map<String, dynamic>> _periods = [];
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
      _periods = await _payroll.listPeriods();
    } catch (_) {}
    setState(() => _loading = false);
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
    await _payroll.createPeriod({
      'period_start': startController.text.trim(),
      'period_end': endController.text.trim(),
    });
    await _load();
  }

  Future<void> _runPayroll(int periodId) async {
    await _payroll.runPayroll(periodId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('payroll')),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _periods.isEmpty
              ? Center(child: Text(l10n.t('payroll_empty')))
              : ListView.builder(
                  itemCount: _periods.length,
                  itemBuilder: (context, i) {
                    final p = _periods[i];
                    final id = int.tryParse(p['id']?.toString() ?? '');
                    return ListTile(
                      title: Text('${p['period_start']} → ${p['period_end']}'),
                      subtitle: Text('${l10n.t('status')}: ${p['status']}'),
                      trailing: id != null && p['status'] != 'closed'
                          ? FilledButton(
                              onPressed: () => _runPayroll(id),
                              child: Text(l10n.t('payroll_run')),
                            )
                          : null,
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(onPressed: _createPeriod, child: const Icon(Icons.add)),
    );
  }
}
