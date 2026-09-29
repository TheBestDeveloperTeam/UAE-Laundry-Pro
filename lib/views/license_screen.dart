import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/services/license_service.dart';
import 'package:laundrypro_uae/services/system_guard_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final _controller = TextEditingController();
  final _license = LicenseService();
  bool _loading = false;
  String? _umac;
  Map<String, dynamic> _status = {};


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final data = await _license.status();
      final hw = await SystemGuardService.getHardwareInfo();
      if (mounted) {
        setState(() {
          _status = data;
          _umac = hw.machineCode;
        });
      }
    } catch (_) {}
  }


  Future<void> _exportLicenseRequest() async {
    try {
      final reqJson = await SystemGuardService.generateLicenseRequestJson();
      final downloadsDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File('${downloadsDir.path}/laundrypro_req.lic');
      await file.writeAsString(reqJson);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0D6E6E),
          content: Text('Request file exported: ${file.path}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _activate() async {
    final l10n = context.l10n;
    final key = _controller.text.trim();
    if (key.isEmpty) return;

    setState(() => _loading = true);
    try {
      await _license.activate(key);
      if (!mounted) return;
      await context.read<AuthProvider>().checkLicense();
      if (!mounted) return;
      context.go('/dashboard');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('license_activate_failed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthProvider>();
    _umac ??= auth.licenseUmac;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('license_title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Trial Status Card
                Card(
                  elevation: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield_outlined, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              l10n.t('trial_active_title'),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Chip(
                              avatar: const Icon(Icons.timer_outlined, size: 16),
                              label: Text(l10n.t('trial_days_remaining', {'days': (_status['trial_days_remaining'] ?? 7).toString()})),
                            ),
                            Chip(
                              avatar: const Icon(Icons.receipt_outlined, size: 16),
                              label: Text(l10n.t('trial_invoices_used', {'used': (_status['invoice_count'] ?? 0).toString()})),
                            ),
                            Chip(
                              avatar: const Icon(Icons.people_outline, size: 16),
                              label: Text(l10n.t('trial_customers_used', {'used': (_status['customer_count'] ?? 0).toString()})),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Activation Card
                Card(
                  elevation: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.t('license_subtitle'), style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 16),
                        if (_umac != null) ...[
                          Text(l10n.t('license_umac'), style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: SelectableText(
                              _umac!,
                              style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            labelText: l10n.t('license_key'),
                            hintText: 'Enter activation stamp or key',
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _loading ? null : _activate,
                          child: _loading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(l10n.t('license_activate')),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _exportLicenseRequest,
                                icon: const Icon(Icons.file_upload_outlined),
                                label: Text(l10n.t('export_license_request')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Paste license content or key directly into input field above.')),
                                  );
                                },
                                icon: const Icon(Icons.file_download_outlined),
                                label: Text(l10n.t('import_signed_license')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

