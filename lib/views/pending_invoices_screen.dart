import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/receipt_model.dart';
import 'package:laundrypro_uae/core/receipt_renderer.dart';
import 'package:laundrypro_uae/peripherals/features/shared/providers/app_providers.dart';
import 'package:laundrypro_uae/models/order_model.dart';
import 'package:laundrypro_uae/services/sales_service.dart';
import 'package:laundrypro_uae/widgets/app_data_table.dart';

class PendingInvoicesScreen extends ConsumerStatefulWidget {
  const PendingInvoicesScreen({super.key, this.salesService});

  final SalesService? salesService;

  @override
  ConsumerState<PendingInvoicesScreen> createState() => _PendingInvoicesScreenState();
}

class _PendingInvoicesScreenState extends ConsumerState<PendingInvoicesScreen> {
  late final SalesService _sales;
  List<OrderModel> _orders = [];
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

  List<OrderModel> get _filteredOrders {
    return _orders.where((o) {
      if (_filterStatus != 'all') {
        if (o.paymentStatus != _filterStatus) return false;
      }
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final orderNo = (o.orderNo ?? '').toLowerCase();
      final custName = (o.customerName ?? '').toLowerCase();
      final custPhone = (o.customerPhone ?? '').toLowerCase();
      return orderNo.contains(q) || custName.contains(q) || custPhone.contains(q);
    }).toList();
  }

  Future<void> _openPaymentDialog(OrderModel order) async {
    final balance = double.tryParse(order.balanceDue?.toString() ?? '0') ?? 0;
    if (balance <= 0) return;

    final amountController = TextEditingController(text: balance.toStringAsFixed(2));
    final refController = TextEditingController();
    String selectedMethod = 'cash';

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('${context.l10n.t('pos_pay')} — ${order.orderNo}'),
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
                        Text('Total: AED ${order.grandTotal ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.w600)),
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
                icon: Icon(PhosphorPhosphorPhosphorIcons.circle()()Circle()),
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

      final orderId = order.id;
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
        if (mounted && updated != null) {
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

  void _showReceiptOptions(OrderModel order) {
    final receipt = ReceiptModel.fromOrderModel(order);
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
              leading: Icon(PhosphorPhosphorIcons.circle()()),
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
                      TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text(context.l10n.t('pos_close'))),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(PhosphorPhosphorIcons.circle()()),
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

  Future<void> _updateStatus(OrderModel order) async {
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
    await _sales.updateStatus(order.id!, selected);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final list = _filteredOrders;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('pending_invoices')),
        actions: [IconButton(onPressed: _load, icon: Icon(PhosphorPhosphorIcons.circle()()))],
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
                      prefixIcon: Icon(PhosphorPhosphorIcons.circle()()),
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
                    ButtonSegment(value: 'all', label: Text(context.l10n.t('all'))),
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
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              clipBehavior: Clip.antiAlias,
              child: AppDataTable(
                columns: [
                  const AppDataTableColumn(label: 'Order #', key: 'order_no'),
                  const AppDataTableColumn(label: 'Customer', key: 'customer_name'),
                  const AppDataTableColumn(label: 'Status', key: 'status'),
                  AppDataTableColumn(
                    label: 'Payment Status', 
                    cellBuilder: (row) {
                      final status = row['payment_status']?.toString().toUpperCase() ?? '';
                      final isPartial = status == 'PARTIAL';
                      return Text(
                        status,
                        style: TextStyle(
                          color: isPartial ? Colors.amber.shade900 : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const AppDataTableColumn(label: 'Total', key: 'grand_total', numeric: true),
                  const AppDataTableColumn(label: 'Balance Due', key: 'balance_due', numeric: true),
                  AppDataTableColumn(
                    label: 'Actions',
                    cellBuilder: (row) {
                      final orderId = row['id'] as int;
                      final order = list.firstWhere((o) => o.id == orderId);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.tonal(
                            onPressed: () => _openPaymentDialog(order),
                            child: const Text('Pay'),
                          ),
                          IconButton(
                            icon: const Icon(PhosphorIcons.circle()),
                            onPressed: () => _showReceiptOptions(order),
                          ),
                        ],
                      );
                    },
                  ),
                ],
                data: list.map((o) => o.toJson()).toList(),
                isLoading: _loading,
                emptyMessage: l10n.t('pending_invoices_empty'),
                onRowTap: (row) {
                  final orderId = row['id'] as int;
                  final order = list.firstWhere((o) => o.id == orderId);
                  _updateStatus(order);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
