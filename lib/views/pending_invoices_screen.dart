import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/receipt_model.dart';
import 'package:laundrypro_uae/core/receipt_renderer.dart';
import 'package:laundrypro_uae/peripherals/core/storage/app_database.dart';
import 'package:laundrypro_uae/peripherals/features/shared/providers/app_providers.dart';
import 'package:laundrypro_uae/models/order_model.dart';
import 'package:laundrypro_uae/services/offline_first_sales_service.dart';
import 'package:laundrypro_uae/services/sales_service.dart';
import 'package:laundrypro_uae/widgets/app_data_table.dart';
import 'package:laundrypro_uae/widgets/order_detail_dialog.dart';
import 'package:laundrypro_uae/widgets/status_badge.dart';

class PendingInvoicesScreen extends ConsumerStatefulWidget {
  const PendingInvoicesScreen({super.key, this.salesService});

  final SalesService? salesService;

  @override
  ConsumerState<PendingInvoicesScreen> createState() => _PendingInvoicesScreenState();
}

class _PendingInvoicesScreenState extends ConsumerState<PendingInvoicesScreen> {
  late SalesService _sales;
  List<OrderModel> _orders = [];
  bool _loading = true;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, pending, partial

  @override
  void initState() {
    super.initState();
    _initSales();
  }

  void _initSales() {
    if (widget.salesService != null) {
      _sales = widget.salesService!;
    } else {
      AppDatabase? db;
      try {
        db = ref.read(appDatabaseProvider);
      } catch (_) {}
      _sales = OfflineFirstSalesService(database: db);
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final pending = await _sales.listPending();
      final partial = await _sales.listPartial();
      if (mounted) {
        setState(() {
          _orders = [...pending, ...partial];
          _loading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.error('Failed to load pending invoices', tag: 'PendingInvoicesScreen', error: e, stackTrace: stack);
      if (mounted) setState(() => _loading = false);
    }
  }

  List<OrderModel> get _filteredOrders {
    return _orders.where((o) {
      if (_filterStatus != 'all') {
        if (o.paymentStatus != _filterStatus) return false;
      }
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final orderNo = o.orderNo.toLowerCase();
      final custName = (o.customerName ?? '').toLowerCase();
      final custPhone = (o.customerPhone ?? '').toLowerCase();
      return orderNo.contains(q) || custName.contains(q) || custPhone.contains(q);
    }).toList();
  }

  Future<void> _openPaymentDialog(OrderModel order) async {
    final l10n = context.l10n;
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
            backgroundColor: AppTokens.surfacePrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusLarge)),
            title: Text('${context.l10n.t('pos_pay')} - ${order.orderNo}', style: AppTokens.sectionHeading),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTokens.space12),
                    decoration: BoxDecoration(
                      color: AppTokens.surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                      border: Border.all(color: AppTokens.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total: AED ${order.grandTotal}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('Balance: AED ${balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTokens.statusCancelled)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.space16),
                  Text(l10n.t('pending_payment_method'), style: const TextStyle(fontSize: 12, color: AppTokens.textSecondary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedMethod,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTokens.surfaceSubtle,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.borderSubtle)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.borderSubtle)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.brandTeal)),
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem(value: 'cash', child: Text(l10n.t('pending_cash'))),
                      DropdownMenuItem(value: 'card', child: Text(l10n.t('pending_card'))),
                      DropdownMenuItem(value: 'cheque', child: Text(l10n.t('pending_cheque'))),
                      DropdownMenuItem(value: 'bank_transfer', child: Text(l10n.t('pending_bank_transfer'))),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedMethod = val);
                    },
                  ),
                  const SizedBox(height: AppTokens.space12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTokens.surfaceSubtle,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.borderSubtle)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.borderSubtle)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.brandTeal)),
                      labelText: l10n.t('pending_amount_label'),
                      prefixText: 'AED ',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  TextField(
                    controller: refController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTokens.surfaceSubtle,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.borderSubtle)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.borderSubtle)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.brandTeal)),
                      labelText: selectedMethod == 'cheque'
                          ? 'Cheque No. / Bank'
                          : 'Reference / Auth No. (Optional)',
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.t('pos_close'))),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTokens.brandTeal, foregroundColor: Colors.white),
                icon: const Icon(Icons.check_circle, size: 18),
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
          } catch (e) {
            AppLogger.warning('Cash drawer pulse failed', tag: 'PendingInvoicesScreen', error: e);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment of AED ${payAmount.toStringAsFixed(2)} posted successfully')),
          );
        }
        await _load();
        if (mounted) {
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
    final l10n = context.l10n;
    final receipt = ReceiptModel.fromOrderModel(order);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLarge))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppTokens.space20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt Options - ${receipt.orderNo}', style: AppTokens.sectionHeading),
            const SizedBox(height: AppTokens.space16),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: AppTokens.brandTeal),
              title: Text(l10n.t('pending_view_thermal')),
              subtitle: Text(l10n.t('pending_thermal_desc')),
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
                      TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(context.l10n.t('pos_close'))),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppTokens.brandTeal),
              title: Text(l10n.t('pending_a4_invoice')),
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
    await _sales.updateStatus(order.id, selected);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final list = _filteredOrders;

    return Scaffold(
      backgroundColor: AppTokens.canvas,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space24, vertical: AppTokens.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.t('live_orders'), style: AppTokens.pageHeading),
                    const SizedBox(height: 2),
                    Text(
                      '${list.length} orders pending payment or processing',
                      style: const TextStyle(fontSize: 13, color: AppTokens.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppTokens.textSecondary),
                  onPressed: _load,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space16),

            // Filter Bar
            Container(
              padding: const EdgeInsets.all(AppTokens.space12),
              decoration: AppTokens.cardDecoration,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppTokens.textMuted),
                        hintText: context.l10n.t('search_orders_hint'),
                        filled: true,
                        fillColor: AppTokens.surfaceSubtle,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.borderSubtle)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.borderSubtle)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.brandTeal)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: AppTokens.space16),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'all', label: Text(context.l10n.t('all'))),
                      const ButtonSegment(value: 'pending', label: Text('Unpaid')),
                      const ButtonSegment(value: 'partial', label: Text('Partial')),
                    ],
                    selected: {_filterStatus},
                    onSelectionChanged: (set) => setState(() => _filterStatus = set.first),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space16),

            // Live Orders Table
            Expanded(
              child: Container(
                decoration: AppTokens.cardDecoration,
                clipBehavior: Clip.antiAlias,
                child: AppDataTable(
                  columns: [
                    const AppDataTableColumn(label: 'Order #', key: 'order_no'),
                    const AppDataTableColumn(label: 'Customer', key: 'customer_name'),
                    AppDataTableColumn(
                      label: 'Status',
                      cellBuilder: (row) {
                        final status = row['status']?.toString().toLowerCase() ?? 'received';
                        OrderStage stage = OrderStage.received;
                        if (status.contains('wash')) stage = OrderStage.washing;
                        if (status.contains('finish') || status.contains('press')) stage = OrderStage.finishing;
                        if (status.contains('ready')) stage = OrderStage.ready;
                        if (status.contains('deliver')) stage = OrderStage.delivered;
                        if (status.contains('cancel') || status.contains('void')) stage = OrderStage.cancelled;
                        return StatusBadge(label: status.toUpperCase(), stage: stage, compact: true);
                      },
                    ),
                    AppDataTableColumn(
                      label: 'Payment Status',
                      cellBuilder: (row) {
                        final status = row['payment_status']?.toString().toUpperCase() ?? '';
                        final isPartial = status == 'PARTIAL';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPartial ? AppTokens.statusBgFinishing : AppTokens.statusBgCancelled,
                            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: isPartial ? AppTokens.statusFinishing : AppTokens.statusCancelled,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                    const AppDataTableColumn(label: 'Total (AED)', key: 'grand_total', numeric: true),
                    const AppDataTableColumn(label: 'Balance Due (AED)', key: 'balance_due', numeric: true),
                    AppDataTableColumn(
                      label: 'Actions',
                      cellBuilder: (row) {
                        final orderId = row['id'] as int;
                        final order = list.firstWhere((o) => o.id == orderId);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTokens.brandTeal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSmall)),
                              ),
                              onPressed: () => _openPaymentDialog(order),
                              child: Text(context.l10n.t('pay_action'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert, size: 18, color: AppTokens.textSecondary),
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
      ),
    );
  }
}
