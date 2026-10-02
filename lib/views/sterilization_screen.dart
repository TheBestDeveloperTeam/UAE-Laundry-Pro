import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/theme.dart';
import '../services/sterilization_service.dart';

class SterilizationScreen extends ConsumerStatefulWidget {
  const SterilizationScreen({super.key, this.sterilizationService});

  final SterilizationService? sterilizationService;

  @override
  ConsumerState<SterilizationScreen> createState() => _SterilizationScreenState();
}

class _SterilizationScreenState extends ConsumerState<SterilizationScreen> {
  final _lotController = TextEditingController(text: 'LOT-2026-AUT01');
  final _orderController = TextEditingController(text: '1');
  final _tempController = TextEditingController(text: '134.5');
  final _pressureController = TextEditingController(text: '3.1');
  final _durationController = TextEditingController(text: '18');
  
  bool _isLoading = false;
  String _selectedProgram = 'Medical Autoclave 134°C (B-Cycle Vacuum)';
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'validated', 'pending'

  final List<String> _autoclavePrograms = [
    'Medical Autoclave 134°C (B-Cycle Vacuum)',
    'Biohazard Linen Decontamination (121°C Steam)',
    'Surgical Textile Penetration (Class B Multi-Pulse)',
    'Low-Temp Formaldehyde Chamber (60°C)'
  ];

  final List<Map<String, dynamic>> _recentLots = [
    {
      'id': 1,
      'lot_number': 'LOT-2026-AUT01',
      'cycle': 'Medical Autoclave 134°C (B-Cycle Vacuum)',
      'temp': '134.5°C',
      'pressure': '3.1 bar',
      'duration': '18 min',
      'status': 'validated',
      'date': '2026-10-02',
      'signature': 'SHA256: 7d9a8f21e03c...',
      'signer': 'QA Lead — Dr. Tariq Al-Hashimi',
    },
    {
      'id': 2,
      'lot_number': 'LOT-2026-BIO09',
      'cycle': 'Biohazard Linen Decontamination (121°C Steam)',
      'temp': '121.0°C',
      'pressure': '2.1 bar',
      'duration': '30 min',
      'status': 'validated',
      'date': '2026-10-01',
      'signature': 'SHA256: 4a2b91c83df0...',
      'signer': 'Sterilization Operator #04',
    },
    {
      'id': 3,
      'lot_number': 'LOT-2026-SUR03',
      'cycle': 'Surgical Textile Penetration (Class B Multi-Pulse)',
      'temp': '134.0°C',
      'pressure': '3.0 bar',
      'duration': '20 min',
      'status': 'pending_sign',
      'date': '2026-10-02',
      'signature': null,
      'signer': null,
    },
  ];

  SterilizationService get _service =>
      widget.sterilizationService ?? ref.read(sterilizationServiceProvider);

  @override
  void dispose() {
    _lotController.dispose();
    _orderController.dispose();
    _tempController.dispose();
    _pressureController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _createBatch() async {
    final lot = _lotController.text.trim();
    if (lot.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _service.batchCreate({
        'lot_number': lot,
        'expiry_date': '2029-12-31',
        'origin_sales_order_id': int.tryParse(_orderController.text) ?? 1,
      });

      final newEntry = {
        'id': _recentLots.length + 1,
        'lot_number': lot,
        'cycle': _selectedProgram,
        'temp': '${_tempController.text}°C',
        'pressure': '${_pressureController.text} bar',
        'duration': '${_durationController.text} min',
        'status': 'pending_sign',
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'signature': null,
        'signer': null,
      };

      setState(() {
        _recentLots.insert(0, newEntry);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.t('sterilization_success')),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signLotDialog(Map<String, dynamic> lot) async {
    final nameController = TextEditingController();
    final pinController = TextEditingController();
    final remarksController = TextEditingController(text: 'DHA Health Standard Compliant — Biological Indicator Negative');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.draw, color: AppTheme.accentTeal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Electronic Signature: ${lot['lot_number']}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '21 CFR Part 11 & DHA Electronic Signature Attestation',
                style: TextStyle(color: AppTheme.secondaryGrey, fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Certified Supervisor / QA Name *',
                  hintText: 'e.g. Dr. Amina Al-Zaabi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Operator Security PIN *',
                  hintText: '4-digit authorization code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(
                  labelText: 'Regulatory Attestation / Meaning *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.verified_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.infoBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppTheme.infoBlue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Signing cryptographically commits this validation log to permanent audit history.',
                        style: TextStyle(fontSize: 11, color: AppTheme.infoBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentTeal,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (nameController.text.trim().isEmpty || pinController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter supervisor name and security PIN'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Sign & Certify'),
          ),
        ],
      ),
    );

    if (result == true) {
      final inputBytes = utf8.encode('${lot['lot_number']}-${nameController.text.trim()}-${DateTime.now().toIso8601String()}');
      final hash = sha256.convert(inputBytes).toString();

      try {
        await _service.signElectronic({
          'cycle_run_id': lot['id'] ?? 1,
          'signature_hash': hash,
          'meaning': remarksController.text.trim(),
        });

        setState(() {
          lot['status'] = 'validated';
          lot['signature'] = 'SHA256: ${hash.substring(0, 16)}...';
          lot['signer'] = nameController.text.trim();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sterilization Lot certified with digital e-signature'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Signing error: $e'), backgroundColor: AppTheme.errorRed),
          );
        }
      }
    }
  }

  void _showLotDetails(Map<String, dynamic> lot) {
    final isValidated = lot['status'] == 'validated';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      lot['lot_number'],
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isValidated
                          ? AppTheme.successGreen.withValues(alpha: 0.12)
                          : AppTheme.warningOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isValidated ? 'VALIDATED' : 'PENDING SIGNATURE',
                      style: TextStyle(
                        color: isValidated ? AppTheme.successGreen : AppTheme.warningOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _detailRow('Autoclave Cycle', lot['cycle']),
              _detailRow('Saturated Steam Temp', lot['temp']),
              _detailRow('Operating Chamber Pressure', lot['pressure']),
              _detailRow('Holding Duration', lot['duration'] ?? '18 min'),
              _detailRow('Cycle Date', lot['date']),
              if (lot['signer'] != null) _detailRow('Certified By', lot['signer']),
              if (lot['signature'] != null) _detailRow('Cryptographic Hash', lot['signature']),
              const SizedBox(height: 20),
              if (!isValidated)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.draw, size: 18),
                    label: const Text('Affix Electronic Signature'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _signLotDialog(lot);
                    },
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Close Details'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredLots {
    return _recentLots.where((lot) {
      final matchesSearch = _searchQuery.isEmpty ||
          lot['lot_number'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lot['cycle'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = switch (_statusFilter) {
        'validated' => lot['status'] == 'validated',
        'pending' => lot['status'] != 'validated',
        _ => true,
      };

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filtered = _filteredLots;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('sterilization')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Status Card
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
                    child: const Icon(Icons.verified, color: AppTheme.accentTeal, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('sterilization'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'ISO 13485, 21 CFR Part 11 & DHA Cleanroom Sterilization Standards',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Batch Lot Creation Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('sterilization_batch_create'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProgram,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Sterilization Autoclave Program',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tune),
                      ),
                      items: _autoclavePrograms.map((prog) {
                        return DropdownMenuItem(value: prog, child: Text(prog, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedProgram = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _lotController,
                            decoration: InputDecoration(
                              labelText: l10n.t('sterilization_lot'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _orderController,
                            decoration: InputDecoration(
                              labelText: l10n.t('order_no'),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tempController,
                            decoration: const InputDecoration(
                              labelText: 'Target Temp (°C)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _pressureController,
                            decoration: const InputDecoration(
                              labelText: 'Pressure (bar)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _durationController,
                            decoration: const InputDecoration(
                              labelText: 'Duration (min)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_outline),
                        onPressed: _isLoading ? null : _createBatch,
                        label: Text(l10n.t('sterilization_batch_create')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // History Filter Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search lots, autoclave programs...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('All'),
                  selected: _statusFilter == 'all',
                  onSelected: (val) {
                    if (val) setState(() => _statusFilter = 'all');
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Validated'),
                  selected: _statusFilter == 'validated',
                  onSelected: (val) {
                    if (val) setState(() => _statusFilter = 'validated');
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Needs Sign'),
                  selected: _statusFilter == 'pending',
                  onSelected: (val) {
                    if (val) setState(() => _statusFilter = 'pending');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recent Lots
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final lot = filtered[i];
                final isValidated = lot['status'] == 'validated';

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    onTap: () => _showLotDetails(lot),
                    leading: CircleAvatar(
                      backgroundColor: (isValidated ? AppTheme.accentTeal : AppTheme.warningOrange).withValues(alpha: 0.15),
                      child: Icon(
                        isValidated ? Icons.done_all : Icons.draw,
                        color: isValidated ? AppTheme.accentTeal : AppTheme.warningOrange,
                      ),
                    ),
                    title: Text(lot['lot_number']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${lot['cycle']} • ${lot['temp']} @ ${lot['pressure']} (${lot['duration'] ?? '18 min'})'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isValidated ? AppTheme.successGreen : AppTheme.warningOrange).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isValidated ? 'VALIDATED' : 'NEEDS SIGN',
                            style: TextStyle(
                              color: isValidated ? AppTheme.successGreen : AppTheme.warningOrange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isValidated) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.draw, color: AppTheme.accentTeal),
                            tooltip: 'Affix Signature',
                            onPressed: () => _signLotDialog(lot),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
