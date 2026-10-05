import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/models/customer_model.dart';
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
  List<CustomerModel> _customers = [];
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
    } catch (e, stack) {
      AppLogger.error('Failed to load customers', tag: 'CustomersScreen', error: e, stackTrace: stack);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _showForm([CustomerModel? existing]) {
    final isNew = existing == null;
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final trnCtrl = TextEditingController(text: existing?.trn ?? '');
    int points = existing?.loyaltyPoints ?? 0;
    String tier = existing?.loyaltyTier ?? 'Bronze';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AppFormDialog(
          title: isNew ? 'Register New Customer' : 'Customer Profile & Loyalty',
          onSave: () async {
            final data = {
              'phone': phoneCtrl.text.trim(),
              'name': nameCtrl.text.trim(),
              'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
              'address': addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
              'trn': trnCtrl.text.trim().isEmpty ? null : trnCtrl.text.trim(),
              'loyalty_points': points,
              'loyalty_tier': tier,
            };
            if (isNew) {
              await _service.create(data);
            } else {
              await _service.update(existing.id, data);
            }
          },
          onSuccess: _load,
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone Number (Mobile) *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Customer Name *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: trnCtrl,
                        decoration: const InputDecoration(labelText: 'Tax TRN (B2B)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.verified)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Delivery Address / Villa / Apt', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home)),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text('Loyalty Program & VIP Status', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: tier,
                        decoration: const InputDecoration(labelText: 'Loyalty Tier', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'Bronze', child: Text('🥉 Bronze Tier')),
                          DropdownMenuItem(value: 'Silver', child: Text('🥈 Silver Tier (5% Disc)')),
                          DropdownMenuItem(value: 'Gold', child: Text('🥇 Gold Tier (10% Disc)')),
                          DropdownMenuItem(value: 'Platinum', child: Text('💎 Platinum VIP (15% Disc)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDlgState(() => tier = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Loyalty Points', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                Text('$points pts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  onPressed: points > 50 ? () => setDlgState(() => points -= 50) : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.teal),
                                  onPressed: () => setDlgState(() => points += 50),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _customers
        : _customers.where((c) =>
            c.name.toLowerCase().contains(query) ||
            (c.phone != null && c.phone!.contains(query)) ||
            (c.email != null && c.email!.toLowerCase().contains(query))).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('customers')),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 340,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search phone, name or email...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
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
                  AppDataTableColumn(label: 'Tier', key: 'loyalty_tier'),
                  AppDataTableColumn(label: 'Points', key: 'loyalty_points', numeric: true),
                  AppDataTableColumn(label: 'Balance', key: 'balance', numeric: true),
                ],
                data: filtered.map((c) => c.toJson()).toList(),
                isLoading: _loading,
                onRowTap: (row) {
                  final id = row['id'] as int;
                  final cust = _customers.firstWhere((c) => c.id == id);
                  _showForm(cust);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
