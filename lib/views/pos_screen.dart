import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/receipt_model.dart';
import 'package:laundrypro_uae/core/receipt_renderer.dart';
import 'package:laundrypro_uae/peripherals/features/shared/providers/app_providers.dart';
import 'package:laundrypro_uae/peripherals/core/scanner/scanner_models.dart';
import 'package:laundrypro_uae/services/catalog_service.dart';
import 'package:laundrypro_uae/services/customer_service.dart';
import 'package:laundrypro_uae/services/peripheral_print_service.dart';
import 'package:laundrypro_uae/services/sales_service.dart';

class CartLine {
  CartLine({
    required this.itemType,
    required this.itemId,
    required this.name,
    required this.rate,
    this.quantity = 1,
    this.discount = 0.0,
    this.modifiers = const [],
    this.vatRate = 0.05,
  });

  final String itemType;
  final int itemId;
  final String name;
  double rate;
  int quantity;
  double discount;
  List<Map<String, dynamic>> modifiers;
  double vatRate;

  double get modifierTotal {
    double total = 0.0;
    for (final m in modifiers) {
      final type = m['price_type']?.toString() ?? 'fixed';
      final val = double.tryParse(m['price_value']?.toString() ?? '0') ?? 0.0;
      if (type == 'percentage') {
        total += (rate * (val / 100.0));
      } else {
        total += val;
      }
    }
    return total;
  }

  double get unitRateWithModifiers => rate + modifierTotal;

  double get lineSubtotal => unitRateWithModifiers * quantity;

  double get lineTotal => (lineSubtotal - discount).clamp(0.0, double.infinity);

  double get vatAmount => lineTotal * vatRate;

  double get lineTotalWithVat => lineTotal + vatAmount;

  Map<String, dynamic> toLine() => {
        'item_type': itemType,
        'item_id': itemId,
        'description': name,
        'quantity': quantity,
        'rate': unitRateWithModifiers,
        'discount': discount,
        'modifiers': modifiers,
      };
}

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({
    super.key,
    this.salesService,
    this.catalogService,
    this.customerService,
  });

  final SalesService? salesService;
  final CatalogService? catalogService;
  final CustomerService? customerService;

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  late final SalesService _sales;
  late final CatalogService _catalog;
  late final CustomerService _customerService;

  final FocusNode _scannerFocus = FocusNode(debugLabel: 'pos-scanner-wedge');
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _products = [];
  final List<CartLine> _cart = [];
  bool _loading = true;
  bool _processing = false;
  Map<String, dynamic>? _confirmedOrder;
  String? _businessName;
  String _searchFilter = '';
  final TextEditingController _searchController = TextEditingController();
  ProviderSubscription<AsyncValue<ScannerPacketModel>>? _scannerSub;

  // Selected customer
  Map<String, dynamic>? _selectedCustomer;
  List<Map<String, dynamic>> _customers = [];

  // Order-level discount
  double _orderDiscount = 0.0;

  @override
  void initState() {
    super.initState();
    _sales = widget.salesService ?? SalesService();
    _catalog = widget.catalogService ?? CatalogService();
    _customerService = widget.customerService ?? CustomerService();
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
    _searchController.dispose();
    _scannerSub?.close();
    _scannerFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final services = await _sales.loadServices();
      final products = await _catalog.listProducts();
      final customers = await _customerService.list();

      Map<String, dynamic> business = {};
      try {
        business = await _sales.getBusiness();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _services = services;
          _products = products;
          _customers = customers;
          _businessName = business['display_name']?.toString() ?? 'LaundryPro UAE';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addLine({
    required String itemType,
    required int itemId,
    required String name,
    required double rate,
    List<Map<String, dynamic>> modifiers = const [],
  }) {
    final existing = _cart.where((l) => l.itemType == itemType && l.itemId == itemId).toList();
    setState(() {
      if (existing.isNotEmpty && modifiers.isEmpty) {
        existing.first.quantity++;
      } else {
        _cart.add(CartLine(
          itemType: itemType,
          itemId: itemId,
          name: name,
          rate: rate,
          modifiers: List.from(modifiers),
        ));
      }
    });
  }

  void _addService(Map<String, dynamic> service) {
    final id = int.tryParse(service['id']?.toString() ?? '') ?? 0;
    final name = service['name']?.toString() ?? '';
    final rate = double.tryParse(service['base_rate']?.toString() ?? '0') ?? 0;
    _addLine(itemType: 'service', itemId: id, name: name, rate: rate);
  }

  void _addProduct(Map<String, dynamic> product) {
    final id = int.tryParse(product['id']?.toString() ?? '') ?? 0;
    final name = product['name']?.toString() ?? '';
    final rate = double.tryParse(product['base_rate']?.toString() ?? '0') ?? 0;
    _addLine(itemType: 'product', itemId: id, name: name, rate: rate);
  }

  Future<void> _handleScan(String code) async {
    if (code.trim().isEmpty || _processing) return;
    final scanned = code.trim();

    // 1. Check Service code
    final service = _services.cast<Map<String, dynamic>?>().firstWhere(
      (s) => s?['code']?.toString() == scanned,
      orElse: () => null,
    );
    if (service != null) {
      _addService(service);
      return;
    }

    // 2. Check Product barcode
    try {
      final product = await _catalog.findProductByBarcode(scanned);
      if (product != null) {
        _addProduct(product);
        return;
      }
    } catch (_) {}

    // 3. Check Customer code
    final customer = _customers.cast<Map<String, dynamic>?>().firstWhere(
      (c) => c?['customer_code']?.toString() == scanned || c?['phone']?.toString() == scanned,
      orElse: () => null,
    );
    if (customer != null) {
      setState(() => _selectedCustomer = customer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Customer Selected: ${customer['name']}')),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('pos_scan_not_found'))),
      );
    }
  }

  double get _linesSubtotal => _cart.fold(0.0, (sum, line) => sum + line.lineTotal);
  double get _taxableAmount => (_linesSubtotal - _orderDiscount).clamp(0.0, double.infinity);
  double get _vatAmount => _taxableAmount * 0.05; // UAE 5% VAT
  double get _grandTotal => _taxableAmount + _vatAmount;

  Future<void> _confirmSale() async {
    if (_cart.isEmpty || _processing) return;
    final l10n = context.l10n;
    setState(() => _processing = true);
    try {
      final draft = await _sales.createDraft(
        customerId: _selectedCustomer?['id'] as int?,
        lines: _cart.map((l) => l.toLine()).toList(),
      );
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
    final total = double.tryParse(_confirmedOrder!['grand_total']?.toString() ?? '0') ?? _grandTotal;

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
        _orderDiscount = 0.0;
        _selectedCustomer = null;
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

  void _selectCustomerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Customer'),
        content: SizedBox(
          width: 450,
          height: 350,
          child: ListView.builder(
            itemCount: _customers.length,
            itemBuilder: (context, i) {
              final c = _customers[i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person, size: 18)),
                title: Text(c['name']?.toString() ?? ''),
                subtitle: Text(c['phone']?.toString() ?? ''),
                onTap: () {
                  setState(() => _selectedCustomer = c);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
          title: Row(
            children: [
              Text(l10n.t('pos')),
              const SizedBox(width: 16),
              // Customer Selection Chip
              ActionChip(
                avatar: const Icon(Icons.person, size: 16),
                label: Text(
                  _selectedCustomer != null
                      ? '${_selectedCustomer!['name']} (${_selectedCustomer!['phone'] ?? ''})'
                      : 'Walk-In Customer (Tap to select)',
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: _selectCustomerDialog,
              ),
              if (_selectedCustomer != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() => _selectedCustomer = null),
                ),
            ],
          ),
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  // Left: Catalog Items (Services & Products)
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.t('pos_services'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              Text(
                                '${_services.length} services • ${_products.length} products',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search services, garments, or barcodes...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchFilter.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchFilter = '';
                                        });
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchFilter = val.trim().toLowerCase();
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final filtered = _services.where((s) {
                                  if (_searchFilter.isEmpty) return true;
                                  final name = (s['name']?.toString() ?? '').toLowerCase();
                                  final code = (s['code']?.toString() ?? '').toLowerCase();
                                  return name.contains(_searchFilter) || code.contains(_searchFilter);
                                }).toList();

                                if (filtered.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade400),
                                        const SizedBox(height: 8),
                                        Text(l10n.t('pos_no_services')),
                                      ],
                                    ),
                                  );
                                }

                                return GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 2.2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, i) {
                                    final s = filtered[i];
                                    final rate = s['base_rate']?.toString() ?? '0';
                                    return OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.all(8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => _addService(s),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            s['name']?.toString() ?? '',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text('AED $rate', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // Right: Cart, Tax Breakdown & Checkout
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.t('pos_cart'), style: Theme.of(context).textTheme.titleMedium),
                              if (_cart.isNotEmpty)
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  label: const Text('Clear'),
                                  onPressed: () => setState(() => _cart.clear()),
                                ),
                            ],
                          ),
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
                                        subtitle: Text(
                                          'Rate: AED ${line.rate.toStringAsFixed(2)} x ${line.quantity}'
                                          '${line.discount > 0 ? ' • Disc: -AED ${line.discount.toStringAsFixed(2)}' : ''}',
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'AED ${line.lineTotal.toStringAsFixed(2)}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
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
                          // Financial Breakdown
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(child: Text('Lines Subtotal:')),
                              Text('AED ${_linesSubtotal.toStringAsFixed(2)}'),
                            ],
                          ),
                          if (_orderDiscount > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(child: Text('Order Discount:')),
                                Text('-AED ${_orderDiscount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(child: Text('UAE VAT (5%):')),
                              Text('AED ${_vatAmount.toStringAsFixed(2)}'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${l10n.t('pos_total')}:',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                'AED ${_grandTotal.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
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
