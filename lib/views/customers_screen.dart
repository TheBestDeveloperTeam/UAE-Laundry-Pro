import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/phone_normalizer.dart';
import 'package:laundrypro_uae/services/customer_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key, this.customerService});

  final CustomerService? customerService;

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late final CustomerService _customers;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _customers = widget.customerService ?? CustomerService();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _customers.list(query: _searchController.text.trim());
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _showCustomerDialog([Map<String, dynamic>? existing]) {
    final isNew = existing == null;
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: existing?['email']?.toString() ?? '');
    final codeCtrl = TextEditingController(text: existing?['customer_code']?.toString() ?? '');
    final addressCtrl = TextEditingController(text: existing?['address_line1']?.toString() ?? '');
    final notesCtrl = TextEditingController(text: existing?['notes']?.toString() ?? '');
    final creditLimitCtrl = TextEditingController(text: existing?['credit_limit']?.toString() ?? '0.00');
    String customerType = existing?['customer_type']?.toString() ?? 'personal';
    String? duplicateWarning;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isNew ? 'New Customer' : 'Edit Customer'),
            content: SizedBox(
              width: 550,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (duplicateWarning != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(duplicateWarning!, style: const TextStyle(fontSize: 12))),
                          ],
                        ),
                      ),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name *'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: phoneCtrl,
                            decoration: const InputDecoration(
                              labelText: 'UAE Phone (e.g. 0501234567) *',
                              helperText: 'Auto-normalizes to UAE standard',
                            ),
                            onChanged: (val) {
                              final norm = PhoneNormalizer.normalizeUaePhone(val);
                              // Check duplicates
                              final match = _items.firstWhere(
                                (c) => PhoneNormalizer.normalizeUaePhone(c['phone']?.toString() ?? '') == norm && c['id'] != existing?['id'],
                                orElse: () => {},
                              );
                              if (match.isNotEmpty) {
                                setDialogState(() {
                                  duplicateWarning = 'Potential duplicate customer detected with same phone (${match['name']})';
                                });
                              } else if (duplicateWarning != null) {
                                setDialogState(() => duplicateWarning = null);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: emailCtrl,
                            decoration: const InputDecoration(labelText: 'Email Address'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeCtrl,
                            decoration: const InputDecoration(labelText: 'Customer Code (e.g. CUST-001)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: customerType,
                            decoration: const InputDecoration(labelText: 'Customer Type'),
                            items: const [
                              DropdownMenuItem(value: 'personal', child: Text('Personal')),
                              DropdownMenuItem(value: 'professional', child: Text('Corporate / B2B')),
                              DropdownMenuItem(value: 'walk_in', child: Text('Walk-In Quick')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => customerType = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(labelText: 'Delivery Address / Villa / Bldg'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: creditLimitCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Credit Limit (AED)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: notesCtrl,
                            decoration: const InputDecoration(labelText: 'Preferences / Notes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;

                  final normPhone = PhoneNormalizer.normalizeUaePhone(phoneCtrl.text.trim());
                  final payload = {
                    'name': name,
                    if (normPhone.isNotEmpty) 'phone': normPhone,
                    if (emailCtrl.text.trim().isNotEmpty) 'email': emailCtrl.text.trim(),
                    if (codeCtrl.text.trim().isNotEmpty) 'customer_code': codeCtrl.text.trim(),
                    'customer_type': customerType,
                    if (addressCtrl.text.trim().isNotEmpty) 'address_line1': addressCtrl.text.trim(),
                    'credit_limit': double.tryParse(creditLimitCtrl.text.trim()) ?? 0.0,
                    if (notesCtrl.text.trim().isNotEmpty) 'notes': notesCtrl.text.trim(),
                  };

                  try {
                    if (isNew) {
                      await _customers.create(payload);
                    } else {
                      await _customers.update(existing['id'] as int, payload);
                    }
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _load();
                  } catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Failed to save customer: $e')),
                    );
                  }
                },
                child: const Text('Save Customer'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search customer by name, normalized phone, or customer code...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.search),
                  label: Text(l10n.t('search')),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(child: Text(l10n.t('catalog_empty')))
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final c = _items[i];
                          final balance = double.tryParse(c['outstanding_balance']?.toString() ?? '0') ?? 0;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text((c['name']?.toString().isNotEmpty == true)
                                    ? c['name']!.toString()[0].toUpperCase()
                                    : 'C'),
                              ),
                              title: Row(
                                children: [
                                  Text(c['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (c['customer_code'] != null && c['customer_code'].toString().isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(c['customer_code'].toString(), style: const TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c['phone']?.toString() ?? 'No phone'),
                                  if (c['address_line1'] != null && c['address_line1'].toString().isNotEmpty)
                                    Text(c['address_line1'].toString(), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'AED ${balance.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: balance > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                        ),
                                      ),
                                      Text('Balance', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _showCustomerDialog(c),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomerDialog(),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Customer'),
      ),
    );
  }
}
