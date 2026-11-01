import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';
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
      if (mounted) {
        setState(() {
          _items = (res['data']?['vendors'] as List? ?? []).map((e) => VendorModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          _loading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.error('Failed to load vendors', tag: 'VendorsScreen', error: e, stackTrace: stack);
      if (mounted) setState(() => _loading = false);
    }
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
          backgroundColor: AppTokens.surfacePrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusLarge)),
          title: Text(isNew ? l10n.t('vendor_add_title') : l10n.t('vendor_edit_title'), style: AppTokens.sectionHeading),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: InputDecoration(labelText: '${l10n.t('vendor_name_field')} *')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: l10n.t('phone_field')))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: emailCtrl, decoration: InputDecoration(labelText: l10n.t('email_field')))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: addressCtrl, decoration: InputDecoration(labelText: l10n.t('address_field'))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: trnCtrl, decoration: const InputDecoration(labelText: 'UAE TRN (Tax No.)'))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: paymentTerms,
                          decoration: const InputDecoration(labelText: 'Payment Terms'),
                          items: const [
                            DropdownMenuItem(value: 'Immediate', child: Text('Immediate / Cash')),
                            DropdownMenuItem(value: 'Net 15', child: Text('Net 15 Days')),
                            DropdownMenuItem(value: 'Net 30', child: Text('Net 30 Days')),
                            DropdownMenuItem(value: 'Net 60', child: Text('Net 60 Days')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDlgState(() => paymentTerms = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: creditLimitCtrl, decoration: const InputDecoration(labelText: 'Credit Limit (AED)'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: bankCtrl, decoration: const InputDecoration(labelText: 'Bank / IBAN Details'))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.t('cancel'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTokens.brandTeal, foregroundColor: Colors.white, elevation: 0),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.t('save'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    final body = {
      'name': name,
      if (phoneCtrl.text.trim().isNotEmpty) 'phone': phoneCtrl.text.trim(),
      if (emailCtrl.text.trim().isNotEmpty) 'email': emailCtrl.text.trim(),
      if (addressCtrl.text.trim().isNotEmpty) 'address': addressCtrl.text.trim(),
      if (trnCtrl.text.trim().isNotEmpty) 'trn': trnCtrl.text.trim(),
      'payment_terms': paymentTerms,
      'credit_limit': double.tryParse(creditLimitCtrl.text.trim()) ?? 0,
      if (bankCtrl.text.trim().isNotEmpty) 'bank_details': bankCtrl.text.trim(),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.t('vendor_save_failed').replaceAll('{error}', e.toString()))));
      }
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
                    Text(l10n.t('vendors'), style: AppTokens.pageHeading),
                    const SizedBox(height: 2),
                    Text(
                      '${_items.length} registered suppliers and commercial vendors',
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
                        hintText: '${l10n.t('search')} by vendor name, phone, or TRN...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppTokens.textMuted),
                        filled: true,
                        fillColor: AppTokens.surfaceSubtle,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.borderSubtle)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.borderSubtle)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium), borderSide: const BorderSide(color: AppTokens.brandTeal)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _load(),
                    ),
                  ),
                  const SizedBox(width: AppTokens.space16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTokens.brandTeal, foregroundColor: Colors.white, elevation: 0),
                    onPressed: () => _openVendorDialog(),
                    icon: const Icon(Icons.add_business, size: 18),
                    label: Text(l10n.t('vendor_add_button'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space16),

            // Vendor Cards List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.storefront_outlined, size: 64, color: AppTokens.textMuted),
                              const SizedBox(height: 12),
                              Text(l10n.t('vendor_none_found'), style: const TextStyle(color: AppTokens.textSecondary, fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppTokens.space10),
                          itemBuilder: (context, i) {
                            final v = _items[i];
                            return Container(
                              decoration: AppTokens.cardDecoration,
                              padding: const EdgeInsets.all(AppTokens.space16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppTokens.brandTeal.withValues(alpha: 0.12),
                                    child: Text(
                                      v.name.isNotEmpty ? v.name[0].toUpperCase() : 'V',
                                      style: const TextStyle(color: AppTokens.brandTeal, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: AppTokens.space16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTokens.textPrimary)),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTokens.surfaceSubtle,
                                                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                                                border: Border.all(color: AppTokens.borderSubtle),
                                              ),
                                              child: Text(
                                                l10n.t('terms_chip_label', {'terms': v.paymentTerms}),
                                                style: const TextStyle(fontSize: 11, color: AppTokens.textSecondary),
                                              ),
                                            ),
                                            if (v.creditLimit > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTokens.surfaceSubtle,
                                                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                                                  border: Border.all(color: AppTokens.borderSubtle),
                                                ),
                                                child: Text(
                                                  l10n.t('credit_chip_label', {'credit': v.creditLimit.toStringAsFixed(0)}),
                                                  style: const TextStyle(fontSize: 11, color: AppTokens.textSecondary),
                                                ),
                                              ),
                                            if (v.trn != null && v.trn!.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTokens.statusBgReceived,
                                                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                                                ),
                                                child: Text(
                                                  l10n.t('trn_chip_label', {'trn': v.trn!}),
                                                  style: const TextStyle(fontSize: 11, color: AppTokens.statusReceived, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (v.phone != null || v.email != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            '${v.phone ?? ''} ${v.email != null ? '• ${v.email}' : ''}',
                                            style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppTokens.textSecondary),
                                    onPressed: () => _openVendorDialog(v),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
