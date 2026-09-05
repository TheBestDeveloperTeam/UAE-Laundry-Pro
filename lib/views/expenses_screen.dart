import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _expenses = widget.expenseService ?? ExpenseService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _expenses.list();
      _categories = await _expenses.listCategories();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _create() async {
    final l10n = context.l10n;
    final amountController = TextEditingController();
    final categoryController = TextEditingController(text: _categories.isNotEmpty ? _categories.first['id']?.toString() : '1');
    final descController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('expense_create')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountController, decoration: InputDecoration(labelText: l10n.t('amount')), keyboardType: TextInputType.number),
            TextField(controller: categoryController, decoration: InputDecoration(labelText: l10n.t('category_id')), keyboardType: TextInputType.number),
            TextField(controller: descController, decoration: InputDecoration(labelText: l10n.t('description'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.t('pos_close'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.t('save'))),
        ],
      ),
    );
    if (ok != true) return;
    final amount = double.tryParse(amountController.text.trim());
    final categoryId = int.tryParse(categoryController.text.trim());
    if (amount == null || categoryId == null) return;
    await _expenses.create({
      'amount': amount,
      'category_id': categoryId,
      if (descController.text.isNotEmpty) 'description': descController.text.trim(),
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('expenses')),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(l10n.t('expenses_empty')))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final e = _items[i];
                    return ListTile(
                      title: Text(e['description']?.toString() ?? l10n.t('expenses')),
                      subtitle: Text('${e['amount']} · ${e['status']}'),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(onPressed: _create, child: const Icon(Icons.add)),
    );
  }
}
