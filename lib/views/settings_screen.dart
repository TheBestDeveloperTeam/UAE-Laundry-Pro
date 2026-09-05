import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/backup_service.dart';
import 'package:laundrypro_uae/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.settingsService, this.backupService});

  final SettingsService? settingsService;
  final BackupService? backupService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsService _settings;
  late final BackupService _backup;
  final _businessNameController = TextEditingController();
  List<Map<String, dynamic>> _backups = [];
  bool _loading = true;
  String? _lastBackupResult;

  @override
  void initState() {
    super.initState();
    _settings = widget.settingsService ?? SettingsService();
    _backup = widget.backupService ?? BackupService();
    _load();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _settings.getSettings();
      final settings = data['settings'] as Map? ?? {};
      _businessNameController.text = settings['business.name']?.toString().replaceAll('"', '') ?? '';
      _backups = await _backup.history();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _saveSettings() async {
    await _settings.updateSettings({'business.name': _businessNameController.text.trim()});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.t('saved'))));
    }
  }

  Future<void> _runBackup() async {
    final result = await _backup.run();
    final verify = await _backup.verify(file: result['file']?.toString());
    setState(() {
      _lastBackupResult = verify['verified'] == true ? context.l10n.t('backup_verified') : context.l10n.t('backup_failed');
    });
    await _load();
  }

  Future<void> _validateRestore() async {
    if (_backups.isEmpty) return;
    final file = _backups.first['file']?.toString();
    final result = await _backup.restoreValidate(file: file);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.t('restore_validate')}: ${result['compatible']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('settings'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(l10n.t('settings_general'), style: Theme.of(context).textTheme.titleMedium),
                TextField(
                  controller: _businessNameController,
                  decoration: InputDecoration(labelText: l10n.t('business_name')),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _saveSettings, child: Text(l10n.t('save'))),
                const Divider(height: 32),
                Text(l10n.t('peripherals'), style: Theme.of(context).textTheme.titleMedium),
                ListTile(
                  leading: const Icon(Icons.devices),
                  title: Text(l10n.t('peripherals')),
                  subtitle: Text(l10n.t('peripherals_settings_hint')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/peripherals'),
                ),
                const Divider(height: 32),
                Text(l10n.t('backup'), style: Theme.of(context).textTheme.titleMedium),
                if (_lastBackupResult != null) Text(_lastBackupResult!),
                FilledButton(onPressed: _runBackup, child: Text(l10n.t('backup_run'))),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _validateRestore, child: Text(l10n.t('restore_validate'))),
                const SizedBox(height: 12),
                ..._backups.take(5).map((b) => ListTile(
                      dense: true,
                      title: Text(b['file']?.toString() ?? ''),
                      subtitle: Text(b['created_at']?.toString() ?? ''),
                    )),
              ],
            ),
    );
  }
}
