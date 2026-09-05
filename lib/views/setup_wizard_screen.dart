import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/install_service.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key, this.installService});

  final InstallService? installService;

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  late final InstallService _install;
  Map<String, dynamic> _status = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _install = widget.installService ?? InstallService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _status = await _install.status();
    } catch (_) {}
    setState(() => _loading = false);
    if (_status['locked'] == true && mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('setup_wizard'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.t('setup_status')),
                  const SizedBox(height: 12),
                  _row(l10n.t('status_connected'), _status['db_connected'] == true),
                  _row(l10n.t('setup_migrations'), _status['migrations_pending'] == false),
                  _row(l10n.t('setup_locked'), _status['locked'] == true),
                  const SizedBox(height: 24),
                  Text(l10n.t('setup_instructions')),
                ],
              ),
            ),
    );
  }

  Widget _row(String label, bool ok) {
    return ListTile(
      leading: Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked, color: ok ? Colors.green : null),
      title: Text(label),
    );
  }
}
