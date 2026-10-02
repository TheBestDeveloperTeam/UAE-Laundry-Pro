import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/theme.dart';
import 'package:laundrypro_uae/models/purchase_order_model.dart';
import 'package:laundrypro_uae/models/vendor_model.dart';
import 'package:laundrypro_uae/services/catalog_service.dart';
import 'package:laundrypro_uae/services/purchase_service.dart';
import 'package:laundrypro_uae/services/api_client.dart';

class PurchasingScreen extends StatefulWidget {
  const PurchasingScreen({super.key, this.purchaseService, this.catalogService});

  final PurchaseService? purchaseService;
  final CatalogService? catalogService;

  @override
  State<PurchasingScreen> createState() => _PurchasingScreenState();
}

class _PurchasingScreenState extends State<PurchasingScreen> {
  late final PurchaseService _purchases;
  late final CatalogService _catalog;
  final ApiClient _api = ApiClient();

  List<PurchaseOrderModel> _items = [];
  List<VendorModel> _vendors = [];
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String _statusFilter = 'all';
  final _currency = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _purchases = widget.purchaseService ?? PurchaseService();
    _catalog = widget.catalogService ?? CatalogService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final filter = _statusFilter == 'all' ? null : _statusFilter;
      final results = await Future.wait([
        _purchases.list(status: filter),
        _loadVendors(),
        _catalog.listProducts(),
      ]);
      _items = results[0] as List<PurchaseOrderModel>;
      _vendors = results[1] as List<VendorModel>;
      _products = results[2] as List<Map<String, dynamic>>;
    } catch (e, stack) {
      AppLogger.error('Failed to load purchase orders', tag: 'PurchasingScreen', error: e, stackTrace: stack);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<List<VendorModel>> _loadVendors() async {
    try {
      final res = await _api.get('/vendors');
      return (res['data']?['vendors'] as List? ?? [])
          .map((e) => VendorModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _getVendorName(int vendorId) {
    final v = _vendors.cast<VendorModel?>().firstWhere(
      (element) => element?.id == vendorId,
      orElse: () => null,
    );
    return v?.name ?? 'Vendor #$vendorId';
  }

  Future<void> _create() async {
    final l10n = context.l10n;
    int? selectedVendorId = _vendors.isNotEmpty ? _vendors.first.id : 1;
    final notesController = TextEditingController();
    
    // Line items for the new PO
    final lines = <Map<String, dynamic>>[];
    if (_products.isNotEmpty) {
      lines.add({
        'product_id': _products.first['id'],
        'product_name': _products.first['name'] ?? 'Product',
        'qty_controller': TextEditingController(text: '10'),
        'cost_controller': TextEditingController(text: (_products.first['cost_price'] ?? '15.00').toString()),
      });
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.add_shopping_cart, color: AppTheme.primaryNavy),
              const SizedBox(width: 10),
              Text(l10n.t('po_create')),
            ],
          ),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vendor selection
                  if (_vendors.isNotEmpty)
                    DropdownButtonFormField<int>(
                      initialValue: selectedVendorId,
                      decoration: InputDecoration(
                        labelText: l10n.t('vendors'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.business_outlined),
                      ),
                      items: _vendors.map((v) {
                        return DropdownMenuItem<int>(
                          value: v.id,
                          child: Text(v.name),
                        );
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedVendorId = val),
                    )
                  else
                    TextField(
                      decoration: InputDecoration(
                        labelText: l10n.t('vendor_id'),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => selectedVendorId = int.tryParse(val) ?? 1,
                    ),
                  const SizedBox(height: 16),

                  // Line Items section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Purchase Order Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryNavy)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Item'),
                        onPressed: () {
                          if (_products.isNotEmpty) {
                            setDialogState(() {
                              lines.add({
                                'product_id': _products.first['id'],
                                'product_name': _products.first['name'] ?? 'Product',
                                'qty_controller': TextEditingController(text: '5'),
                                'cost_controller': TextEditingController(text: (_products.first['cost_price'] ?? '10.00').toString()),
                              });
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (lines.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      alignment: Alignment.center,
                      child: const Text('No line items added. Click "+ Add Item" above.'),
                    )
                  else
                    ...lines.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final line = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<int>(
                                initialValue: line['product_id'] as int?,
                                decoration: const InputDecoration(
                                  labelText: 'Product',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: _products.map((p) {
                                  return DropdownMenuItem<int>(
                                    value: p['id'] as int?,
                                    child: Text(p['name']?.toString() ?? 'Product', overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setDialogState(() {
                                    line['product_id'] = val;
                                    final p = _products.firstWhere((element) => element['id'] == val, orElse: () => {});
                                    line['product_name'] = p['name'] ?? 'Product';
                                    if (p['cost_price'] != null) {
                                      (line['cost_controller'] as TextEditingController).text = p['cost_price'].toString();
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: line['qty_controller'] as TextEditingController,
                                decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder(), isDense: true),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: line['cost_controller'] as TextEditingController,
                                decoration: const InputDecoration(labelText: 'Unit Cost', border: OutlineInputBorder(), isDense: true, prefixText: 'AED '),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 20),
                              onPressed: () {
                                setDialogState(() => lines.removeAt(idx));
                              },
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(labelText: l10n.t('notes'), border: const OutlineInputBorder()),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.t('pos_close'))),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryNavy),
              icon: const Icon(Icons.check, size: 18),
              onPressed: () => Navigator.pop(ctx, true),
              label: Text(l10n.t('save')),
            ),
          ],
        ),
      ),
    );

    if (ok != true || selectedVendorId == null) return;

    double calculatedTotal = 0.0;
    final payloadLines = <Map<String, dynamic>>[];
    for (final line in lines) {
      final qty = double.tryParse((line['qty_controller'] as TextEditingController).text.trim()) ?? 0.0;
      final cost = double.tryParse((line['cost_controller'] as TextEditingController).text.trim()) ?? 0.0;
      if (qty > 0) {
        calculatedTotal += qty * cost;
        payloadLines.add({
          'product_id': line['product_id'],
          'quantity_ordered': qty,
          'unit_cost': cost,
        });
      }
    }

    try {
      await _purchases.create({
        'vendor_id': selectedVendorId,
        'total_amount': calculatedTotal,
        'lines': payloadLines,
        if (notesController.text.isNotEmpty) 'notes': notesController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase order created successfully'), backgroundColor: AppTheme.successGreen),
        );
      }
      await _load();
    } catch (e, stack) {
      AppLogger.error('Failed to create purchase order', tag: 'PurchasingScreen', error: e, stackTrace: stack);
    }
  }

  /// Full GRN (Goods Received Note) quantity verification flow
  Future<void> _receiveGoods(PurchaseOrderModel po) async {
    final id = po.id;
    if (id == 0) return;

    // Fetch full PO details with line items
    PurchaseOrderModel fullPo = po;
    try {
      fullPo = await _purchases.get(id);
    } catch (e) {
      AppLogger.warning('Could not fetch detailed PO lines, using cached model: $e', tag: 'PurchasingScreen');
    }

    // Map each line to received quantity text controller
    final lineQtyControllers = <int, TextEditingController>{};
    for (final line in fullPo.lines) {
      lineQtyControllers[line.id] = TextEditingController(text: line.quantityRemaining.toStringAsFixed(0));
    }

    final billOfLadingController = TextEditingController();
    final receivingNotesController = TextEditingController();

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2, color: AppTheme.accentTeal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Goods Received Note (GRN)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('PO: ${fullPo.poNo} · ${_getVendorName(fullPo.vendorId)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryNavy.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order Total: ${_currency.format(fullPo.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('Status: ${fullPo.status.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Line Items Verification',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryNavy),
                  ),
                  const SizedBox(height: 8),

                  if (fullPo.lines.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('No specific item lines found for this PO. Full batch receipt will be recorded.'),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(3),
                          1: FlexColumnWidth(1.5),
                          2: FlexColumnWidth(1.5),
                          3: FlexColumnWidth(2),
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.shade100),
                            children: const [
                              Padding(padding: EdgeInsets.all(8), child: Text('Item / Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Padding(padding: EdgeInsets.all(8), child: Text('Ordered', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                              Padding(padding: EdgeInsets.all(8), child: Text('Received', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                              Padding(padding: EdgeInsets.all(8), child: Text('Receiving Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.right)),
                            ],
                          ),
                          ...fullPo.lines.map((line) {
                            final ctrl = lineQtyControllers[line.id]!;
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(line.productName ?? 'Product #${line.productId}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                      Text('Unit Cost: ${_currency.format(line.unitCost)}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text('${line.quantityOrdered.toInt()}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text('${line.quantityReceived.toInt()}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: line.isFullyReceived ? AppTheme.successGreen : Colors.black87)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: TextField(
                                    controller: ctrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      hintText: '0',
                                      enabled: !line.isFullyReceived,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: billOfLadingController,
                    decoration: const InputDecoration(
                      labelText: 'Supplier Delivery Note / Bill of Lading (BOL)',
                      hintText: 'e.g. DN-984321',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: receivingNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Receiving Inspector Notes / Quality Checks',
                      hintText: 'Packaging intact, seals verified, stored in Bay A',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.accentTeal, foregroundColor: Colors.white),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              onPressed: () => Navigator.pop(ctx, true),
              label: const Text('Confirm GRN Receipt'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    // Build line receipt array
    final receiptLinesPayload = <Map<String, dynamic>>[];
    for (final line in fullPo.lines) {
      final ctrl = lineQtyControllers[line.id];
      final qty = double.tryParse(ctrl?.text.trim() ?? '0') ?? 0.0;
      if (qty > 0) {
        receiptLinesPayload.add({
          'purchase_order_line_id': line.id,
          'product_id': line.productId,
          'quantity': qty,
        });
      }
    }

    // Fallback: If no lines existed on PO, receive as complete PO batch
    final combinedNotes = [
      if (billOfLadingController.text.isNotEmpty) 'BOL: ${billOfLadingController.text.trim()}',
      if (receivingNotesController.text.isNotEmpty) receivingNotesController.text.trim(),
    ].join(' | ');

    setState(() => _loading = true);
    try {
      await _purchases.receive(id, {
        if (receiptLinesPayload.isNotEmpty) 'lines': receiptLinesPayload,
        'notes': combinedNotes,
        'received_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GRN confirmed for ${fullPo.poNo}! Inventory and stock updated.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
      await _load();
    } catch (e, stack) {
      AppLogger.error('Failed to confirm GRN receipt for PO #$id', tag: 'PurchasingScreen', error: e, stackTrace: stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to receive goods: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('purchasing')),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Purchase Orders (${_items.length} records)', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Icon(Icons.shopping_bag_outlined),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('All')),
                    ButtonSegment(value: 'pending', label: Text('Pending')),
                    ButtonSegment(value: 'partial', label: Text('Partial')),
                    ButtonSegment(value: 'received', label: Text('Received')),
                  ],
                  selected: {_statusFilter},
                  onSelectionChanged: (set) {
                    setState(() => _statusFilter = set.first);
                    _load();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(child: Text(l10n.t('purchasing_empty')))
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final po = _items[i];
                          final status = po.status;
                          final isReceived = status == 'received';
                          final isPartial = status == 'partial';

                          Color badgeColor = Colors.blue.shade900;
                          Color badgeBg = Colors.blue.shade100;
                          IconData iconData = Icons.receipt_long;

                          if (isReceived) {
                            badgeColor = AppTheme.successGreen;
                            badgeBg = Colors.green.shade50;
                            iconData = Icons.inventory_2;
                          } else if (isPartial) {
                            badgeColor = Colors.orange.shade800;
                            badgeBg = Colors.orange.shade50;
                            iconData = Icons.pending_actions;
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: badgeBg,
                              child: Icon(iconData, color: badgeColor),
                            ),
                            title: Row(
                              children: [
                                Text(po.poNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text('${_getVendorName(po.vendorId)} · Total: ${_currency.format(po.totalAmount)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isReceived)
                                  FilledButton.tonalIcon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: isPartial ? Colors.orange.shade100 : null,
                                      foregroundColor: isPartial ? Colors.orange.shade900 : null,
                                    ),
                                    icon: const Icon(Icons.download_done, size: 16),
                                    label: Text(isPartial ? 'Receive Balance (GRN)' : 'Receive GRN'),
                                    onPressed: () => _receiveGoods(po),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, size: 14, color: AppTheme.successGreen),
                                        SizedBox(width: 4),
                                        Text('Stock Updated', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        tooltip: l10n.t('po_create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
