import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/payroll_service.dart';

class SalaryAdvancesScreen extends StatefulWidget {
  const SalaryAdvancesScreen({super.key, this.payrollService});

  final PayrollService? payrollService;

  @override
  State<SalaryAdvancesScreen> createState() => _SalaryAdvancesScreenState();
}

class _SalaryAdvancesScreenState extends State<SalaryAdvancesScreen> {
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
      _items = await _payroll.listSalaryAdvances();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _create() async {
    final l10n = context.l10n;
    final employeeController = TextEditingController();
    final amountController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('salary_advance_create')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: employeeController, decoration: InputDecoration(labelText: l10n.t('employee_id')), keyboardType: TextInputType.number),
            TextField(controller: amountController, decoration: InputDecoration(labelText: l10n.t('amount')), keyboardType: TextInputType.number),
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
    final amount = double.tryParse(amountController.text.trim());
    if (employeeId == null || amount == null) return;
    await _payroll.createSalaryAdvance({
      'employee_id': employeeId,
      'amount': amount,
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('salary_advances')),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(l10n.t('empty_data')))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final a = _items[i];
                    return ListTile(
                      title: Text('${l10n.t('employee_id')}: ${a['employee_id']}'),
                      subtitle: Text('Amount: ${a['amount']}'),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(onPressed: _create, child: const Icon(Icons.add)),
    );
  }
}
