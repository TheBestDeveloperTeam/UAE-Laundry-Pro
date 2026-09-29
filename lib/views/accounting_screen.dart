import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/accounting_service.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key, this.accountingService});
  final AccountingService? accountingService;

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  late final AccountingService _service;
  List<Map<String, dynamic>> _batches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = widget.accountingService ?? AccountingService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _batches = await _service.listBatches();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _export() async {
    final fmt = DateFormat('yyyy-MM-dd');
    final to = fmt.format(DateTime.now());
    final from = fmt.format(DateTime.now().subtract(const Duration(days: 30)));
    await _service.export(periodStart: from, periodEnd: to);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('accounting_export')),
        actions: [IconButton(icon: const Icon(Icons.upload_file), onPressed: _export)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _batches.isEmpty
              ? Center(child: Text(l10n.t('reports_empty')))
              : ListView.builder(
                  itemCount: _batches.length,
                  itemBuilder: (_, i) {
                    final b = _batches[i];
                    return ListTile(
                      title: Text('${b['period_start']} — ${b['period_end']}'),
                      subtitle: Text('${b['adapter']} • ${b['status']}'),
                    );
                  },
                ),
    );
  }
}
