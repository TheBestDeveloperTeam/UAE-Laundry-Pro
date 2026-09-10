import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/customer_service.dart';
import 'package:laundrypro_uae/widgets/app_data_table.dart';
import 'package:laundrypro_uae/widgets/app_form_dialog.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key, this.customerService});

  final CustomerService? customerService;

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late final CustomerService _service;
  List<Map<String, dynamic>> _customers = [];
  bool _loading = true;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = widget.customerService ?? CustomerService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _service.list();
      if (mounted) {
        setState(() => _customers = res);
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _showForm([Map<String, dynamic>? existing]) {
    final isNew = existing == null;
    final phoneCtrl = TextEditingController(text: existing?['phone']?.toString() ?? '');
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final type = existing?['customer_type']?.toString() ?? 'retail';

    showDialog(
      context: context,
      builder: (ctx) => AppFormDialog(
        title: isNew ? 'New Customer' : 'Edit Customer',
        onSave: () async {
          final data = {
            'phone': phoneCtrl.text.trim(),
            'name': nameCtrl.text.trim(),
            'customer_type': type,
          };
          if (isNew) {
            await _service.create(data);
          } else {
            await _service.update(existing['id'] as int, data);
          }
        },
        onSuccess: _load,
        content: Column(
          children: [
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number *')),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('customers')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search phone or name...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showForm(),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Customer'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              clipBehavior: Clip.antiAlias,
              child: AppDataTable(
                columns: const [
                  AppDataTableColumn(label: 'Phone', key: 'phone'),
                  AppDataTableColumn(label: 'Name', key: 'name'),
                  AppDataTableColumn(label: 'Type', key: 'customer_type'),
                  AppDataTableColumn(label: 'Balance', key: 'outstanding_balance', numeric: true),
                ],
                data: _customers,
                isLoading: _loading,
                onRowTap: (row) => _showForm(row as Map<String, dynamic>),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
