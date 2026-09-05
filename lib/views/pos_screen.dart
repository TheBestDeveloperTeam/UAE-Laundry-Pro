import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/receipt_model.dart';
import 'package:laundrypro_uae/core/receipt_renderer.dart';
import 'package:laundrypro_uae/peripherals/features/shared/providers/app_providers.dart';
import 'package:laundrypro_uae/peripherals/core/scanner/scanner_models.dart';
import 'package:laundrypro_uae/services/catalog_service.dart';
import 'package:laundrypro_uae/services/peripheral_print_service.dart';
import 'package:laundrypro_uae/services/sales_service.dart';

class CartLine {
  CartLine({
    required this.itemType,
    required this.itemId,
    required this.name,
    required this.rate,
    this.quantity = 1,
  });

  final String itemType;
  final int itemId;
  final String name;
  final double rate;
  int quantity;

  double get amount => rate * quantity;

  Map<String, dynamic> toLine() => {
        'item_type': itemType,
        'item_id': itemId,
        'description': name,
        'quantity': quantity,
        'rate': rate,
      };
}

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key, this.salesService, this.catalogService});

  final SalesService? salesService;
  final CatalogService? catalogService;

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  late final SalesService _sales;
  late final CatalogService _catalog;
  final FocusNode _scannerFocus = FocusNode(debugLabel: 'pos-scanner-wedge');
  List<Map<String, dynamic>> _services = [];
  final List<CartLine> _cart = [];
  bool _loading = true;
  bool _processing = false;
  Map<String, dynamic>? _confirmedOrder;
  String? _businessName;
  ProviderSubscription<AsyncValue<ScannerPacketModel>>? _scannerSub;

  @override
  void initState() {
    super.initState();
    _sales = widget.salesService ?? SalesService();
    _catalog = widget.catalogService ?? CatalogService();
    _load();
    _scannerSub = ref.listenManual<AsyncValue<ScannerPacketModel>>(
      scannerPacketsProvider,
      (_, next) {
        final packet = next.valueOrNull;
        if (packet != null) {
          _handleScan(packet.decodedValue);
        }
      },
    );
  }

  @override
  void dispose() {
    _scannerSub?.close();
    _scannerFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final services = await _sales.loadServices();
      Map<String, dynamic> business = {};
      try {
        business = await _sales.getBusiness();
      } catch (_) {}
      setState(() {
        _services = services;
        _businessName = business['display_name']?.toString();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _addLine({
    required String itemType,
    required int itemId,
    required String name,
    required double rate,
  }) {
    final existing = _cart.where((l) => l.itemType == itemType && l.itemId == itemId).toList();
    setState(() {
      if (existing.isNotEmpty) {
        existing.first.quantity++;
      } else {
        _cart.add(CartLine(itemType: itemType, itemId: itemId, name: name, rate: rate));
      }
    });
  }

  void _addService(Map<String, dynamic> service) {
    final id = int.tryParse(service['id']?.toString() ?? '') ?? 0;
    final name = service['name']?.toString() ?? '';
    final rate = double.tryParse(service['base_rate']?.toString() ?? '0') ?? 0;
    _addLine(itemType: 'service', itemId: id, name: name, rate: rate);
  }

  Future<void> _handleScan(String code) async {
    if (code.trim().isEmpty || _processing) return;
    final scanned = code.trim();
    final service = _services.cast<Map<String, dynamic>?>().firstWhere(
      (s) => s?['code']?.toString() == scanned,
      orElse: () => null,
    );
    if (service != null) {
      _addService(service);
      return;
    }

    try {
      final product = await _catalog.findProductByBarcode(scanned);
      if (product != null) {
        final id = int.tryParse(product['id']?.toString() ?? '') ?? 0;
        final name = product['name']?.toString() ?? '';
        final rate = double.tryParse(product['base_rate']?.toString() ?? '0') ?? 0;
        _addLine(itemType: 'product', itemId: id, name: name, rate: rate);
        return;
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('pos_scan_not_found'))),
      );
    }
  }

  double get _subtotal => _cart.fold(0, (sum, line) => sum + line.amount);

  Future<void> _confirmSale() async {
    if (_cart.isEmpty || _processing) return;
    final l10n = context.l10n;
    setState(() => _processing = true);
    try {
      final draft = await _sales.createDraft(lines: _cart.map((l) => l.toLine()).toList());
      final orderId = int.tryParse(draft['id']?.toString() ?? '') ?? 0;
      final confirmed = await _sales.confirm(orderId);
      setState(() {
        _confirmedOrder = confirmed;
        _processing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.t('pos_confirmed')}: ${confirmed['order_no']}')),
        );
      }
    } catch (_) {
      setState(() => _processing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('pos_confirm_failed'))),
        );
      }
    }
  }

  Future<void> _pay() async {
    if (_confirmedOrder == null || _processing) return;
    final l10n = context.l10n;
    final orderId = int.tryParse(_confirmedOrder!['id']?.toString() ?? '') ?? 0;
    final total = double.tryParse(_confirmedOrder!['grand_total']?.toString() ?? '0') ?? _subtotal;

    final payment = await showDialog<_PaymentResult>(
      context: context,
      builder: (ctx) => _PaymentDialog(total: total),
    );
    if (payment == null) return;

    setState(() => _processing = true);
    try {
      final paid = await _sales.postPayment(
        orderId,
        amount: payment.amount,
        method: payment.method,
      );
      setState(() => _processing = false);
      if (!mounted) return;

      if (payment.method == 'cash') {
        final drawer = _printService();
        final drawerResult = await drawer.openCashDrawer();
        if (!drawerResult.success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t('peripherals_drawer_failed'))),
          );
        }
      }

      await _showReceipt(paid);
      setState(() {
        _cart.clear();
        _confirmedOrder = null;
      });
    } catch (_) {
      setState(() => _processing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('pos_payment_failed'))),
        );
      }
    }
  }

  PeripheralPrintService _printService() {
    return PeripheralPrintService(
      printerManager: ref.read(printerManagerProvider),
      selectedPrinter: ref.read(selectedPrinterProvider),
      arabicCodePage: ref.read(arabicCodePageProvider),
      reverseArabicRtl: ref.read(reverseArabicRtlProvider),
      paper: ref.read(paperSizeProvider),
      copies: ref.read(printCopiesProvider),
    );
  }

  Future<void> _showReceipt(Map<String, dynamic> order) async {
    final l10n = context.l10n;
    final receipt = ReceiptModel.fromOrder(order);
    final preview = ReceiptRenderer.toThermal(receipt);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('pos_receipt')),
        content: SingleChildScrollView(child: Text(preview)),
        actions: [
          TextButton(
            onPressed: () async {
              final result = await _printService().printOrder(
                order,
                businessName: _businessName,
              );
              if (!ctx.mounted) return;
              if (!result.success) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.error ?? l10n.t('pos_print_failed'),
                    ),
                  ),
                );
              }
            },
            child: Text(l10n.t('pos_print')),
          ),
          TextButton(
            onPressed: () async {
              final bytes = await ReceiptRenderer.toA4Pdf(receipt);
              final dir = Directory.systemTemp;
              final file = File('${dir.path}/receipt_${receipt.orderNo}.pdf');
              await file.writeAsBytes(bytes);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('${l10n.t('pos_print_pdf')}: ${file.path}')),
                );
              }
            },
            child: Text(l10n.t('pos_print_pdf')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('pos_close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return KeyboardListener(
      autofocus: true,
      focusNode: _scannerFocus,
      onKeyEvent: ref.read(scannerControllerProvider),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.t('pos')),
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l10n.t('pos_services'), style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Expanded(
                            child: _services.isEmpty
                                ? Center(child: Text(l10n.t('pos_no_services')))
                                : GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 2.2,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemCount: _services.length,
                                    itemBuilder: (context, i) {
                                      final s = _services[i];
                                      final rate = s['base_rate']?.toString() ?? '0';
                                      return OutlinedButton(
                                        onPressed: () => _addService(s),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(s['name']?.toString() ?? '', textAlign: TextAlign.center),
                                            Text(rate, style: Theme.of(context).textTheme.bodySmall),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l10n.t('pos_cart'), style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Expanded(
                            child: _cart.isEmpty
                                ? Center(child: Text(l10n.t('pos_cart_empty')))
                                : ListView.builder(
                                    itemCount: _cart.length,
                                    itemBuilder: (context, i) {
                                      final line = _cart[i];
                                      return ListTile(
                                        title: Text(line.name),
                                        subtitle: Text('${line.rate} x ${line.quantity}'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(line.amount.toStringAsFixed(2)),
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline),
                                              onPressed: () {
                                                setState(() {
                                                  if (line.quantity > 1) {
                                                    line.quantity--;
                                                  } else {
                                                    _cart.removeAt(i);
                                                  }
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const Divider(),
                          Text('${l10n.t('pos_subtotal')}: ${_subtotal.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          if (_confirmedOrder == null)
                            FilledButton(
                              key: const Key('pos_confirm_btn'),
                              onPressed: _cart.isEmpty || _processing ? null : _confirmSale,
                              child: _processing
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Text(l10n.t('pos_confirm')),
                            )
                          else ...[
                            Text('${l10n.t('pos_confirmed')}: ${_confirmedOrder!['order_no']}'),
                            const SizedBox(height: 8),
                            FilledButton(
                              key: const Key('pos_pay_btn'),
                              onPressed: _processing ? null : _pay,
                              child: Text(l10n.t('pos_pay')),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PaymentResult {
  const _PaymentResult({required this.amount, required this.method});

  final double amount;
  final String method;
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.total});

  final double total;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late final TextEditingController _controller;
  String _method = 'cash';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.total.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.t('pos_pay')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.t('pos_amount')),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'cash', label: Text(l10n.t('pos_payment_cash'))),
              ButtonSegment(value: 'card', label: Text(l10n.t('pos_payment_card'))),
            ],
            selected: {_method},
            onSelectionChanged: (selection) {
              setState(() => _method = selection.first);
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.t('pos_close'))),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(_controller.text) ?? 0;
            if (amount > 0) {
              Navigator.pop(context, _PaymentResult(amount: amount, method: _method));
            }
          },
          child: Text(l10n.t('pos_pay')),
        ),
      ],
    );
  }
}
