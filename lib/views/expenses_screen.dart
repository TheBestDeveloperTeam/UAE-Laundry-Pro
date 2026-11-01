import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/services/expense_service.dart';
import 'package:laundrypro_uae/widgets/status_badge.dart';

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
      final items = await _expenses.list(status: filter);
      final categories = await _expenses.listCategories();
      if (mounted) {
        setState(() {
          _items = items;
          _categories = categories;
          _loading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.error('Failed to load expenses or categories', tag: 'ExpensesScreen', error: e, stackTrace: stack);
      if (mounted) setState(() => _loading = false);
    }
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
            backgroundColor: AppTokens.surfacePrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
              side: const BorderSide(color: AppTokens.borderSubtle),
            ),
            title: Text(l10n.t('expense_create'), style: AppTokens.sectionHeading),
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
                  const SizedBox(height: AppTokens.space12),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: '${l10n.t('amount')} (AED)',
                      prefixText: 'AED ',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: l10n.t('description'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.pickFiles(
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
                          icon: const Icon(Icons.attach_file, size: 16),
                          label: Text(
                            attachmentName ?? 'Attach Receipt (Optional)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (attachmentPath != null) ...[
                        const SizedBox(width: AppTokens.space8),
                        IconButton(
                          icon: const Icon(Icons.clear, color: AppTokens.statusCancelled),
                          onPressed: () => setDialogState(() {
                            attachmentPath = null;
                            attachmentName = null;
                          }),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.t('pos_close'), style: const TextStyle(color: AppTokens.textSecondary)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppTokens.brandTeal),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.t('save')),
              ),
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.t('expense_upload_failed').replaceAll('{error}', e.toString()))));
        }
      }
    }
    
    await _load();
  }

  Future<void> _approve(int id) async {
    try {
      await _expenses.approve(id);
      await _load();
    } catch (e, stack) {
      AppLogger.error('Failed to approve expense $id', tag: 'ExpensesScreen', error: e, stackTrace: stack);
    }
  }

  Future<void> _reject(int id) async {
    try {
      await _expenses.reject(id);
      await _load();
    } catch (e, stack) {
      AppLogger.error('Failed to reject expense $id', tag: 'ExpensesScreen', error: e, stackTrace: stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppTokens.canvas,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space24, vertical: AppTokens.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.t('expenses'), style: AppTokens.pageHeading),
                    const SizedBox(height: 2),
                    Text(
                      'Petty cash disbursements, operational vouchers and receipt tracking',
                      style: AppTokens.caption.copyWith(color: AppTokens.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded, color: AppTokens.textSecondary),
                  tooltip: l10n.t('refresh'),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space16),

            // Summary Bar
            Container(
              padding: const EdgeInsets.all(AppTokens.space12),
              decoration: BoxDecoration(
                color: AppTokens.surfacePrimary,
                borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                border: Border.all(color: AppTokens.borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16, vertical: AppTokens.space10),
                      decoration: BoxDecoration(
                        color: AppTokens.surfaceSubtle,
                        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                        border: Border.all(color: AppTokens.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Total Expenses (${_items.length} items):',
                              style: AppTokens.bodyStrong,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'AED ${_totalExpenses.toStringAsFixed(2)}',
                            style: AppTokens.metricLarge.copyWith(fontSize: 18, color: AppTokens.brandTeal),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.space12),
                  Flexible(
                    child: SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'all', label: Text(context.l10n.t('all'))),
                        ButtonSegment(value: 'pending', label: Text(context.l10n.t('pending_invoices'))),
                        ButtonSegment(value: 'approved', label: Text(l10n.t('expense_approved'))),
                      ],
                      selected: {_statusFilter},
                      onSelectionChanged: (set) {
                        setState(() => _statusFilter = set.first);
                        _load();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space16),

            // Expense Records List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTokens.brandTeal))
                  : _items.isEmpty
                      ? Center(
                          child: Text(
                            l10n.t('expenses_empty'),
                            style: AppTokens.bodyRegular.copyWith(color: AppTokens.textMuted),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppTokens.space8),
                          itemBuilder: (context, i) {
                            final e = _items[i];
                            final id = int.tryParse(e['id']?.toString() ?? '0') ?? 0;
                            final status = e['status']?.toString() ?? 'pending';
                            final isPending = status == 'pending';
                            final isApproved = status == 'approved';

                            return Container(
                              decoration: AppTokens.cardDecoration,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: AppTokens.space16, vertical: AppTokens.space8),
                                leading: CircleAvatar(
                                  backgroundColor: isApproved
                                      ? AppTokens.statusBgReady
                                      : (isPending ? AppTokens.statusBgFinishing : AppTokens.statusBgCancelled),
                                  child: Icon(
                                    isApproved
                                        ? Icons.check
                                        : (isPending ? Icons.hourglass_top : Icons.close),
                                    color: isApproved
                                        ? AppTokens.statusReady
                                        : (isPending ? AppTokens.statusFinishing : AppTokens.statusCancelled),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        e['description']?.toString() ?? l10n.t('expenses'),
                                        style: AppTokens.bodyStrong,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: AppTokens.space8),
                                    StatusBadge(
                                      label: status.toUpperCase(),
                                      stage: isApproved
                                          ? OrderStage.ready
                                          : (isPending ? OrderStage.finishing : OrderStage.cancelled),
                                      compact: true,
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  'Category #${e['category_id'] ?? ''}',
                                  style: AppTokens.caption.copyWith(color: AppTokens.textSecondary),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'AED ${double.tryParse(e['amount']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
                                      style: AppTokens.bodyStrong,
                                    ),
                                    if (isPending) ...[
                                      const SizedBox(width: AppTokens.space8),
                                      IconButton(
                                        icon: const Icon(Icons.check_circle, color: AppTokens.statusReady),
                                        tooltip: l10n.t('expense_approve_tooltip'),
                                        onPressed: id > 0 ? () => _approve(id) : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel, color: AppTokens.statusCancelled),
                                        tooltip: l10n.t('expense_reject_tooltip'),
                                        onPressed: id > 0 ? () => _reject(id) : null,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTokens.brandTeal,
        foregroundColor: Colors.white,
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: Text(l10n.t('expense_create')),
      ),
    );
  }
}
