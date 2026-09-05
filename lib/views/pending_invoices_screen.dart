import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/sales_service.dart';

class PendingInvoicesScreen extends StatefulWidget {
  const PendingInvoicesScreen({super.key, this.salesService});

  final SalesService? salesService;

  @override
  State<PendingInvoicesScreen> createState() => _PendingInvoicesScreenState();
}

class _PendingInvoicesScreenState extends State<PendingInvoicesScreen> {
  late final SalesService _sales;
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _sales = widget.salesService ?? SalesService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final pending = await _sales.listPending();
      final partial = await _sales.listPartial();
      setState(() {
        _orders = [...pending, ...partial];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pay(Map<String, dynamic> order) async {
    final balance = double.tryParse(order['balance_due']?.toString() ?? '0') ?? 0;
    if (balance <= 0) return;
    final controller = TextEditingController(text: balance.toStringAsFixed(2));
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.t('pos_pay')),
        content: TextField(controller: controller, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.t('pos_close'))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text)),
            child: Text(context.l10n.t('pos_pay')),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    await _sales.postPayment(int.parse(order['id'].toString()), amount: amount);
    await _load();
  }

  Future<void> _updateStatus(Map<String, dynamic> order) async {
    const statuses = ['confirmed', 'processing', 'ready', 'delivered', 'closed'];
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(context.l10n.t('update_status')),
        children: statuses
            .map((s) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, s), child: Text(s)))
            .toList(),
      ),
    );
    if (selected == null) return;
    await _sales.updateStatus(int.parse(order['id'].toString()), selected);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('pending_invoices')),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(child: Text(l10n.t('pending_invoices_empty')))
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, i) {
                    final o = _orders[i];
                    return ListTile(
                      title: Text(o['order_no']?.toString() ?? ''),
                      subtitle: Text('${o['status']} · ${o['payment_status']}'),
                      trailing: Text(o['balance_due']?.toString() ?? '0'),
                      onTap: () => _updateStatus(o),
                      onLongPress: () => _pay(o),
                    );
                  },
                ),
    );
  }
}
