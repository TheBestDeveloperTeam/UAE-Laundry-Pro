import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/theme.dart';
import 'package:laundrypro_uae/services/business_service.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key, this.businessService});

  final BusinessService? businessService;

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  late final BusinessService _business;
  final _nameController = TextEditingController();
  final _trnController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String _selectedCurrency = 'AED';
  double _vatRate = 5.0;

  @override
  void initState() {
    super.initState();
    _business = widget.businessService ?? BusinessService();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _trnController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await _business.getProfile();
      _nameController.text = profile['name']?.toString() ?? 'UAE Laundry Pro LLC';
      _trnController.text = profile['trn']?.toString() ?? '100492817200003';
      _emailController.text = profile['email']?.toString() ?? 'operations@uaelaundrypro.ae';
      _phoneController.text = profile['phone']?.toString() ?? '+971 4 398 1234';
      _addressController.text = profile['address']?.toString() ?? 'Al Quoz Industrial Area 3, Dubai, UAE';
      _selectedCurrency = profile['currency']?.toString() ?? 'AED';
      _vatRate = double.tryParse(profile['vat_rate']?.toString() ?? '5.0') ?? 5.0;
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _business.updateProfile({
        'name': _nameController.text.trim(),
        'trn': _trnController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'currency': _selectedCurrency,
        'vat_rate': _vatRate,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.t('saved')),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.t('save_failed')),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('business_profile')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero branding card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryNavy, AppTheme.primaryNavy.withValues(alpha: 0.85)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.business, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameController.text.isEmpty ? 'UAE Laundry Pro LLC' : _nameController.text,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'TRN: ${_trnController.text.isEmpty ? '100492817200003' : _trnController.text} • 5% VAT Registered',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Fields Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: l10n.t('business_name'),
                              prefixIcon: const Icon(Icons.storefront, color: AppTheme.primaryNavy),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _trnController,
                            decoration: InputDecoration(
                              labelText: l10n.t('business_trn'),
                              prefixIcon: const Icon(Icons.receipt_long, color: AppTheme.accentTeal),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: l10n.t('business_email'),
                                    prefixIcon: const Icon(Icons.email, color: AppTheme.primaryNavy),
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  decoration: InputDecoration(
                                    labelText: l10n.t('phone'),
                                    prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryNavy),
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: l10n.t('business_address'),
                              prefixIcon: const Icon(Icons.location_on, color: AppTheme.primaryNavy),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedCurrency,
                                  decoration: const InputDecoration(
                                    labelText: 'Primary Business Currency',
                                    prefixIcon: Icon(Icons.currency_exchange, color: AppTheme.primaryNavy),
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'AED', child: Text('AED — United Arab Emirates Dirham (د.إ)')),
                                    DropdownMenuItem(value: 'SAR', child: Text('SAR — Saudi Riyal (ر.س)')),
                                    DropdownMenuItem(value: 'QAR', child: Text('QAR — Qatari Riyal (ر.ق)')),
                                    DropdownMenuItem(value: 'OMR', child: Text('OMR — Omani Rial (ر.ع.)')),
                                    DropdownMenuItem(value: 'BHD', child: Text('BHD — Bahraini Dinar (.د.ب)')),
                                    DropdownMenuItem(value: 'KWD', child: Text('KWD — Kuwaiti Dinar (د.ك)')),
                                    DropdownMenuItem(value: 'USD', child: Text('USD — US Dollar (\$)')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedCurrency = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<double>(
                                  initialValue: _vatRate,
                                  decoration: const InputDecoration(
                                    labelText: 'Standard VAT Rate',
                                    prefixIcon: Icon(Icons.percent, color: AppTheme.accentTeal),
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 0.0, child: Text('0% (Exempt)')),
                                    DropdownMenuItem(value: 5.0, child: Text('5% (UAE FTA)')),
                                    DropdownMenuItem(value: 15.0, child: Text('15% (KSA ZATCA)')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _vatRate = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryNavy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                _saving ? 'Saving...' : l10n.t('save'),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
