import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/expense_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key, this.expenseService});

  final ExpenseService? expenseService;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  late final ExpenseService _expenses;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _expenses = widget.expenseService ?? ExpenseService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final filter = _statusFilter == 'all' ? null : _statusFilter;
      _items = await _expenses.list(status: filter);
      _categories = await _expenses.listCategories();
    } catch (_) {}
    setState(() => _loading = false);
  }

  double get _totalExpenses {
    return _items.fold<double>(0.0, (sum, e) => sum + (double.tryParse(e['amount']?.toString() ?? '0') ?? 0.0));
  }

  Future<void> _create() async {
    final l10n = context.l10n;
    final amountController = TextEditingController();
    final descController = TextEditingController();
    int? selectedCatId = _categories.isNotEmpty ? int.tryParse(_categories.first['id']?.toString() ?? '1') : 1;
    String? attachmentPath;
    String? attachmentName;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l10n.t('expense_create')),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedCatId,
                    decoration: InputDecoration(
                      labelText: l10n.t('category_id'),
                      border: const OutlineInputBorder(),
                    ),
                    items: _categories.map((c) {
                      final id = int.tryParse(c['id']?.toString() ?? '0') ?? 0;
                      final name = c['name']?.toString() ?? 'Category $id';
                      return DropdownMenuItem<int>(value: id, child: Text(name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCatId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: '${l10n.t('amount')} (AED)',
                      prefixText: 'AED ',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: l10n.t('description'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                          );
                          if (result != null && result.files.single.path != null) {
                            setDialogState(() {
                              attachmentPath = result.files.single.path;
                              attachmentName = result.files.single.name;
                            });
                          }
                        },
                        icon: const Icon(Icons.attach_file),
                        label: Text(attachmentName ?? 'Attach Receipt (Optional)'),
                      ),
                      if (attachmentPath != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () => setDialogState(() {
                            attachmentPath = null;
                            attachmentName = null;
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.t('pos_close'))),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.t('save'))),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || selectedCatId == null) return;
    final created = await _expenses.create({
      'amount': amount,
      'category_id': selectedCatId,
      if (descController.text.isNotEmpty) 'description': descController.text.trim(),
    });
    
    final expenseId = int.tryParse(created['id']?.toString() ?? '0') ?? 0;
    if (expenseId > 0 && attachmentPath != null) {
      try {
        await _expenses.uploadAttachment(expenseId, attachmentPath!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload attachment: $e')));
        }
      }
    }
    
    await _load();
  }

  Future<void> _approve(int id) async {
    try {
      await _expenses.approve(id);
      await _load();
    } catch (_) {}
  }

  Future<void> _reject(int id) async {
    try {
      await _expenses.reject(id);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('expenses')),
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
                          Text('Total Expenses (${_items.length} items):', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('AED ${_totalExpenses.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary)),
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
                    ButtonSegment(value: 'approved', label: Text('Approved')),
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
                    ? Center(child: Text(l10n.t('expenses_empty')))
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final e = _items[i];
                          final id = int.tryParse(e['id']?.toString() ?? '0') ?? 0;
                          final status = e['status']?.toString() ?? 'pending';
                          final isPending = status == 'pending';
                          final isApproved = status == 'approved';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isApproved
                                  ? Colors.green.shade100
                                  : (isPending ? Colors.amber.shade100 : Colors.red.shade100),
                              child: Icon(
                                isApproved
                                    ? Icons.check
                                    : (isPending ? Icons.hourglass_top : Icons.close),
                                color: isApproved
                                    ? Colors.green.shade800
                                    : (isPending ? Colors.amber.shade900 : Colors.red.shade800),
                              ),
                            ),
                            title: Text(e['description']?.toString() ?? l10n.t('expenses'), style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Category #${e['category_id'] ?? ''} - Status: ${status.toUpperCase()}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'AED ${double.tryParse(e['amount']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                if (isPending) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    tooltip: 'Approve',
                                    onPressed: id > 0 ? () => _approve(id) : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    tooltip: 'Reject',
                                    onPressed: id > 0 ? () => _reject(id) : null,
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _create, child: const Icon(Icons.add)),
    );
  }
}
