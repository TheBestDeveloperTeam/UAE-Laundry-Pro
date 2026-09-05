import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/services/license_service.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUmac();
  }

  Future<void> _loadUmac() async {
    try {
      final data = await _license.status();
      if (mounted) setState(() => _umac = data['umac']?.toString());
    } catch (_) {}
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.t('license_subtitle'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (_umac != null) ...[
              Text(l10n.t('license_umac')),
              SelectableText(_umac!, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: l10n.t('license_key'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _activate,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.t('license_activate')),
            ),
          ],
        ),
      ),
    );
  }
}
