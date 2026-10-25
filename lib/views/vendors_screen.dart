import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/services/api_client.dart';
import '../models/vendor_model.dart';

class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key});

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  final _api = ApiClient();
  final _searchController = TextEditingController();
  List<VendorModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
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
      final q = _searchController.text.trim();
      final path = q.isNotEmpty ? '/vendors?q=$q' : '/vendors';
      final res = await _api.get(path);
      _items = (res['data']?['vendors'] as List? ?? []).map((e) => VendorModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e, stack) {
      AppLogger.error('Failed to load vendors', tag: 'VendorsScreen', error: e, stackTrace: stack);
    }
    setState(() => _loading = false);
  }

  Future<void> _openVendorDialog([VendorModel? existing]) async {
    final l10n = context.l10n;
    final isNew = existing == null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final trnCtrl = TextEditingController(text: existing?.trn ?? '');
    final creditLimitCtrl = TextEditingController(text: existing != null && existing.creditLimit > 0 ? existing.creditLimit.toStringAsFixed(2) : '');
    final bankCtrl = TextEditingController(text: existing?.bankDetails ?? '');
    String paymentTerms = existing?.paymentTerms ?? 'Net 30';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Row(
            children: [
              Icon(isNew ? Icons.add_business : Icons.store, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(isNew ? l10n.t('vendor_register_new') : l10n.t('vendor_edit_profile')),
            ],
          ),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: l10n.t('vendor_company_name'), border: const OutlineInputBorder()),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          decoration: InputDecoration(labelText: l10n.t('vendor_phone_number'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.phone)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: emailCtrl,
                          decoration: InputDecoration(labelText: l10n.t('vendor_email_address'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.email)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(labelText: l10n.t('vendor_billing_address'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.location_on)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: trnCtrl,
                          decoration: InputDecoration(labelText: l10n.t('vendor_trn_label'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.verified)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: paymentTerms,
                          decoration: InputDecoration(labelText: l10n.t('vendor_payment_terms'), border: const OutlineInputBorder()),
                          items: [
                            DropdownMenuItem(value: 'Immediate / Cash', child: Text(l10n.t('terms_immediate_cash'))),
                            DropdownMenuItem(value: 'Net 7', child: Text(l10n.t('terms_net_7'))),
                            DropdownMenuItem(value: 'Net 15', child: Text(l10n.t('terms_net_15'))),
                            DropdownMenuItem(value: 'Net 30', child: Text(l10n.t('terms_net_30'))),
                            DropdownMenuItem(value: 'Net 60', child: Text(l10n.t('terms_net_60'))),
                            DropdownMenuItem(value: 'Net 90', child: Text(l10n.t('terms_net_90'))),
                          ],
                          onChanged: (val) {
                            if (val != null) setDlgState(() => paymentTerms = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: creditLimitCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.t('vendor_credit_limit'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.account_balance_wallet)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bankCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.t('vendor_bank_details'),
                      hintText: 'e.g. Emirates NBD, IBAN: AE070260000000000000000',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.account_balance),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.t('pos_close'))),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: Text(context.l10n.t('save')),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final body = {
      'name': nameCtrl.text.trim(),
      'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
      'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
      'address': addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
      'trn': trnCtrl.text.trim().isEmpty ? null : trnCtrl.text.trim(),
      'payment_terms': paymentTerms,
      'credit_limit': double.tryParse(creditLimitCtrl.text.trim()) ?? 0.0,
      'bank_details': bankCtrl.text.trim().isEmpty ? null : bankCtrl.text.trim(),
    };

    try {
      if (isNew) {
        await _api.post('/vendors', body: body);
      } else {
        await _api.put('/vendors/${existing.id}', body: body);
      }
      await _load();
    } catch (e, st) {
      AppLogger.error('Failed to save vendor', tag: 'VendorsScreen', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save vendor: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('vendors')),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '${l10n.t('search')} by vendor name, phone, or TRN...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.storefront, size: 64, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(l10n.t('vendor_none_found'), style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final v = _items[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                child: Text(v.name.isNotEmpty ? v.name[0].toUpperCase() : 'V', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Chip(
                                        label: Text(l10n.t('terms_chip_label', {'terms': v.paymentTerms})),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      ),
                                      if (v.creditLimit > 0)
                                        Chip(
                                          label: Text(l10n.t('credit_chip_label', {'credit': v.creditLimit.toStringAsFixed(0)})),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                      if (v.trn != null && v.trn!.isNotEmpty)
                                        Chip(
                                          avatar: const Icon(Icons.verified, size: 14),
                                          label: Text(l10n.t('trn_chip_label', {'trn': v.trn!})),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                    ],
                                  ),
                                  if (v.phone != null || v.email != null) ...[
                                    const SizedBox(height: 4),
                                    Text('${v.phone ?? ''} ${v.email != null ? '• ${v.email}' : ''}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openVendorDialog(v),
                              ),
                              isThreeLine: true,
                              onTap: () => _openVendorDialog(v),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openVendorDialog(),
        icon: const Icon(Icons.add_business),
        label: Text(l10n.t('vendor_add_button')),
      ),
    );
  }
}
