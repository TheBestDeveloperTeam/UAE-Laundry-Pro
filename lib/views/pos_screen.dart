import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/sales_service.dart';

class CartLine {
  CartLine({
    required this.serviceId,
    required this.name,
    required this.rate,
    this.quantity = 1,
  });

  final int serviceId;
  final String name;
  final double rate;
  int quantity;

  double get amount => rate * quantity;

  Map<String, dynamic> toLine() => {
        'item_type': 'service',
        'item_id': serviceId,
        'description': name,
        'quantity': quantity,
        'rate': rate,
      };
}

class PosScreen extends StatefulWidget {
  const PosScreen({super.key, this.salesService});

  final SalesService? salesService;

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  late final SalesService _sales;
  List<Map<String, dynamic>> _services = [];
  final List<CartLine> _cart = [];
  bool _loading = true;
  bool _processing = false;
  Map<String, dynamic>? _confirmedOrder;
  String? _businessName;

  @override
  void initState() {
    super.initState();
    _sales = widget.salesService ?? SalesService();
    _load();
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

  void _addService(Map<String, dynamic> service) {
    final id = int.tryParse(service['id']?.toString() ?? '') ?? 0;
    final name = service['name']?.toString() ?? '';
    final rate = double.tryParse(service['base_rate']?.toString() ?? '0') ?? 0;
    final existing = _cart.where((l) => l.serviceId == id).toList();
    setState(() {
      if (existing.isNotEmpty) {
        existing.first.quantity++;
      } else {
        _cart.add(CartLine(serviceId: id, name: name, rate: rate));
      }
    });
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

    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => _PaymentDialog(total: total),
    );
    if (amount == null) return;

    setState(() => _processing = true);
    try {
      final paid = await _sales.postPayment(orderId, amount: amount);
      setState(() => _processing = false);
      if (!mounted) return;
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

  Future<void> _showReceipt(Map<String, dynamic> order) async {
    final l10n = context.l10n;
    final lines = (order['lines'] as List?) ?? _cart.map((l) => {
          'description': l.name,
          'quantity': l.quantity,
          'amount': l.amount,
        }).toList();
    final buffer = StringBuffer();
    buffer.writeln(_businessName ?? l10n.t('app_name'));
    buffer.writeln('${l10n.t('pos_receipt_order')}: ${order['order_no']}');
    buffer.writeln('---');
    for (final line in lines) {
      final m = line as Map;
      buffer.writeln('${m['description']} x${m['quantity']}  ${m['amount']}');
    }
    buffer.writeln('---');
    buffer.writeln('${l10n.t('pos_total')}: ${order['grand_total']}');
    buffer.writeln('${l10n.t('pos_paid')}: ${order['amount_paid']}');

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('pos_receipt')),
        content: SingleChildScrollView(child: Text(buffer.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('pos_print')),
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
    return Scaffold(
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
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.total});

  final double total;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late final TextEditingController _controller;

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
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: l10n.t('pos_amount')),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.t('pos_close'))),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(_controller.text) ?? 0;
            if (amount > 0) Navigator.pop(context, amount);
          },
          child: Text(l10n.t('pos_pay')),
        ),
      ],
    );
  }
}
