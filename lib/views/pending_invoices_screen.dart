import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/receipt_model.dart';
import 'package:laundrypro_uae/core/receipt_renderer.dart';
import 'package:laundrypro_uae/peripherals/features/shared/providers/app_providers.dart';
import 'package:laundrypro_uae/services/sales_service.dart';

class PendingInvoicesScreen extends ConsumerStatefulWidget {
  const PendingInvoicesScreen({super.key, this.salesService});

  final SalesService? salesService;

  @override
  ConsumerState<PendingInvoicesScreen> createState() => _PendingInvoicesScreenState();
}

class _PendingInvoicesScreenState extends ConsumerState<PendingInvoicesScreen> {
  late final SalesService _sales;
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, pending, partial

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

  List<Map<String, dynamic>> get _filteredOrders {
    return _orders.where((o) {
      if (_filterStatus != 'all') {
        if (o['payment_status'] != _filterStatus) return false;
      }
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final orderNo = (o['order_no']?.toString() ?? '').toLowerCase();
      final custName = (o['customer_name']?.toString() ?? o['customer']?['name']?.toString() ?? '').toLowerCase();
      final custPhone = (o['customer_phone']?.toString() ?? o['customer']?['phone']?.toString() ?? '').toLowerCase();
      return orderNo.contains(q) || custName.contains(q) || custPhone.contains(q);
    }).toList();
  }

  Future<void> _openPaymentDialog(Map<String, dynamic> order) async {
    final balance = double.tryParse(order['balance_due']?.toString() ?? '0') ?? 0;
    if (balance <= 0) return;

    final amountController = TextEditingController(text: balance.toStringAsFixed(2));
    final refController = TextEditingController();
    String selectedMethod = 'cash';

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('${context.l10n.t('pos_pay')} — ${order['order_no']}'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total: AED ${order['grand_total'] ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('Balance: AED ${balance.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Payment Method / طريقة الدفع:', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedMethod,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash / نقدي')),
                      DropdownMenuItem(value: 'card', child: Text('Card / بطاقة ائتمان')),
                      DropdownMenuItem(value: 'cheque', child: Text('Cheque / شيك')),
                      DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer / تحويل بنكي')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedMethod = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Amount (AED) / المبلغ',
                      prefixText: 'AED ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: refController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: selectedMethod == 'cheque'
                          ? 'Cheque No. / Bank'
                          : 'Reference / Auth No. (Optional)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.t('pos_close'))),
              FilledButton.icon(
                icon: const Icon(Icons.check_circle),
                onPressed: () => Navigator.pop(ctx, true),
                label: Text(context.l10n.t('pos_pay')),
              ),
            ],
          );
        },
      ),
    );

    if (submitted == true) {
      final payAmount = double.tryParse(amountController.text) ?? 0;
      if (payAmount <= 0) return;

      final orderId = int.tryParse(order['id']?.toString() ?? '');
      if (orderId == null) return;

      try {
        final updated = await _sales.postPayment(
          orderId,
          amount: payAmount,
          method: selectedMethod,
          referenceNumber: refController.text.trim(),
        );

        if (selectedMethod == 'cash') {
          try {
            final manager = ref.read(printerManagerProvider);
            final selPrinter = ref.read(selectedPrinterProvider);
            if (selPrinter != null && selPrinter.isNotEmpty) {
              await manager.printToInstalledPrinter(
                printerName: selPrinter,
                payload: manager.cashDrawerPulse(),
              );
            }
          } catch (_) {}
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment of AED ${payAmount.toStringAsFixed(2)} posted successfully')),
          );
        }
        await _load();
        if (mounted && updated.isNotEmpty) {
          _showReceiptOptions(updated);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to post payment: $e')),
          );
        }
      }
    }
  }

  void _showReceiptOptions(Map<String, dynamic> order) {
    final receipt = ReceiptModel.fromOrder(order);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt Options — ${receipt.orderNo}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('View Thermal Receipt Preview'),
              subtitle: const Text('Text format with 5% VAT breakdown'),
              onTap: () {
                Navigator.pop(ctx);
                final text = ReceiptRenderer.toThermal(receipt);
                showDialog(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: Text('Thermal Receipt: ${receipt.orderNo}'),
                    content: SingleChildScrollView(
                      child: SelectableText(
                        text,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Close')),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Generate & View A4 Tax Invoice'),
              subtitle: const Text('Compliant UAE VAT Tax Invoice format'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final pdfBytes = await ReceiptRenderer.toA4Pdf(receipt);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('A4 Tax Invoice generated (${pdfBytes.length} bytes)')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PDF generation failed: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(Map<String, dynamic> order) async {
    const statuses = ['confirmed', 'processing', 'ready', 'delivered', 'closed'];
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(context.l10n.t('update_status')),
        children: statuses
            .map((s) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, s), child: Text(s.toUpperCase())))
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
    final list = _filteredOrders;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('pending_invoices')),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search order #, customer name, phone...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('All')),
                    ButtonSegment(value: 'pending', label: Text('Unpaid')),
                    ButtonSegment(value: 'partial', label: Text('Partial')),
                  ],
                  selected: {_filterStatus},
                  onSelectionChanged: (set) => setState(() => _filterStatus = set.first),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? Center(child: Text(l10n.t('pending_invoices_empty')))
                    : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final o = list[i];
                          final balance = double.tryParse(o['balance_due']?.toString() ?? '0') ?? 0;
                          final isPartial = o['payment_status'] == 'partial';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isPartial ? Colors.amber.shade100 : Colors.red.shade100,
                              child: Icon(
                                isPartial ? Icons.hourglass_bottom : Icons.pending,
                                color: isPartial ? Colors.amber.shade900 : Colors.red.shade900,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(o['order_no']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    (o['status']?.toString() ?? '').toUpperCase(),
                                    style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              'Customer: ${o['customer_name'] ?? o['customer']?['name'] ?? 'Walk-In'} · Total: AED ${o['grand_total'] ?? '0.00'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Due: AED ${balance.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
                                    ),
                                    Text(
                                      (o['payment_status']?.toString() ?? '').toUpperCase(),
                                      style: TextStyle(fontSize: 11, color: isPartial ? Colors.amber.shade900 : Colors.red.shade700),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                FilledButton.tonal(
                                  onPressed: () => _openPaymentDialog(o),
                                  child: const Text('Pay'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () => _showReceiptOptions(o),
                                ),
                              ],
                            ),
                            onTap: () => _updateStatus(o),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
