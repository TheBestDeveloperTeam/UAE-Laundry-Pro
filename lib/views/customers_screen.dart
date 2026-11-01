import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';
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
    final l10n = context.l10n;
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
            if (ctx.mounted) Navigator.pop(ctx);
            await _load();
          },
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.t('customer_phone_label'),
                    prefixIcon: const Icon(Icons.phone, size: 20, color: AppTokens.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.t('customer_name_label'),
                    prefixIcon: const Icon(Icons.person, size: 20, color: AppTokens.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: emailCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.t('customer_email_label'),
                          prefixIcon: const Icon(Icons.email, size: 20, color: AppTokens.textMuted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: trnCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.t('customer_trn_label'),
                          prefixIcon: const Icon(Icons.verified, size: 20, color: AppTokens.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.t('customer_address_label'),
                    prefixIcon: const Icon(Icons.home, size: 20, color: AppTokens.textMuted),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppTokens.borderSubtle),
                const SizedBox(height: 8),
                const Text('Loyalty Program & VIP Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: tier,
                        decoration: InputDecoration(
                          labelText: l10n.t('customer_loyalty_label'),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Bronze', child: Text('Bronze Tier', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Silver', child: Text('Silver Tier (5%)', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Gold', child: Text('Gold Tier (10%)', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Platinum', child: Text('Platinum VIP (15%)', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (val) {
                          if (val != null) setDlgState(() => tier = val);
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTokens.borderSubtle),
                        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                        color: AppTokens.surfaceSubtle,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Loyalty Points', style: TextStyle(fontSize: 10, color: AppTokens.textMuted)),
                              Text('$points pts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTokens.brandTeal)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppTokens.textMuted),
                            onPressed: points > 50 ? () => setDlgState(() => points -= 50) : null,
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.add_circle_outline, size: 20, color: AppTokens.brandTeal),
                            onPressed: () => setDlgState(() => points += 50),
                          ),
                        ],
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
                    Text(l10n.t('customers'), style: AppTokens.pageHeading),
                    const SizedBox(height: 2),
                    Text(
                      '${_customers.length} registered customers & loyalty accounts',
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

            // Search Bar & Action
            Container(
              padding: const EdgeInsets.all(AppTokens.space12),
              decoration: AppTokens.cardDecoration,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search phone, name or email...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppTokens.textMuted),
                        filled: true,
                        fillColor: AppTokens.surfaceSubtle,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.borderSubtle)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.borderSubtle)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.brandTeal)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: AppTokens.space16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTokens.brandTeal, foregroundColor: Colors.white, elevation: 0),
                    onPressed: () => _showForm(),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space16),

            // Customers Table
            Expanded(
              child: Container(
                decoration: AppTokens.cardDecoration,
                clipBehavior: Clip.antiAlias,
                child: AppDataTable(
                  columns: const [
                    AppDataTableColumn(label: 'Phone', key: 'phone'),
                    AppDataTableColumn(label: 'Customer Name', key: 'name'),
                    AppDataTableColumn(label: 'Tier', key: 'loyalty_tier'),
                    AppDataTableColumn(label: 'Points', key: 'loyalty_points', numeric: true),
                    AppDataTableColumn(label: 'Balance (AED)', key: 'balance', numeric: true),
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
      ),
    );
  }
}
