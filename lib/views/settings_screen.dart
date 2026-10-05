import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/theme.dart';
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
    } catch (e, stack) {
      AppLogger.error('Failed to load system settings or backup history', tag: 'SettingsScreen', error: e, stackTrace: stack);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveSettings() async {
    await _settings.updateSettings({'business.name': _businessNameController.text.trim()});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.t('saved'))));
    }
  }

  Future<void> _runBackup() async {
    setState(() => _loading = true);
    try {
      final result = await _backup.run();
      final verify = await _backup.verify(file: result['file']?.toString());
      setState(() {
        _lastBackupResult = verify['verified'] == true ? context.l10n.t('backup_verified') : context.l10n.t('backup_failed');
      });
    } catch (_) {
      setState(() => _lastBackupResult = context.l10n.t('backup_failed'));
    }
    await _load();
  }

  Future<void> _verifyBackupFile(String fileName) async {
    final l10n = context.l10n;
    setState(() => _loading = true);
    try {
      final result = await _backup.verify(file: fileName);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  result['verified'] == true ? Icons.check_circle : Icons.error,
                  color: result['verified'] == true ? AppTheme.successGreen : AppTheme.errorRed,
                ),
                const SizedBox(width: 8),
                Text(result['verified'] == true ? l10n.t('backup_verified') : l10n.t('backup_failed')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('File: $fileName', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${l10n.t('backup_checksum')}:', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                SelectableText(
                  result['checksum_sha256']?.toString() ?? 'N/A',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.t('pos_close'))),
            ],
          ),
        );
      }
    } catch (e, stack) {
      AppLogger.error('Failed to generate system backup', tag: 'SettingsScreen', error: e, stackTrace: stack);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _handleRestore(String fileName) async {
    final l10n = context.l10n;
    setState(() => _loading = true);

    Map<String, dynamic> validation = {};
    try {
      validation = await _backup.restoreValidate(file: fileName);
    } catch (e, stack) {
      AppLogger.error('Failed to validate backup archive for restore', tag: 'SettingsScreen', error: e, stackTrace: stack);
    }
    setState(() => _loading = false);

    if (!mounted) return;

    final isCompatible = validation['compatible'] == true;
    final stCount = validation['statement_count'] ?? 0;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 28),
            const SizedBox(width: 10),
            Text(l10n.t('restore_confirm_title')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.t('restore_confirm_warning'), style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Target Archive: $fileName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Dry Run Status: ${isCompatible ? "PASS" : "FAIL"} ($stCount SQL statements)', style: TextStyle(fontSize: 12, color: isCompatible ? AppTheme.successGreen : AppTheme.errorRed, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.t('pos_close'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: isCompatible ? () => Navigator.pop(ctx, true) : null,
            child: Text(l10n.t('restore_run')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await _backup.restore(file: fileName, confirm: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.t('restore_success')),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.t('backup_failed')),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
    await _load();
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
                // General Settings Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.t('settings_general'), style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _businessNameController,
                          decoration: InputDecoration(
                            labelText: l10n.t('business_name'),
                            prefixIcon: const Icon(Icons.storefront_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryNavy),
                          onPressed: _saveSettings,
                          child: Text(l10n.t('save')),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Peripherals & Hardware Card
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.devices, color: AppTheme.primaryNavy),
                        title: Text(l10n.t('peripherals'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(l10n.t('peripherals_settings_hint')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/settings/peripherals'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.folder_outlined, color: AppTheme.primaryNavy),
                        title: const Text('Global Paths & Directories', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Backup, logs, receipts, images, and export directories'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/settings/global-config'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.security_outlined, color: AppTheme.primaryNavy),
                        title: const Text('Roles & Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Manage user authorization and access roles'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/settings/roles'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Database Backup & Disaster Recovery Card (Sprint 20)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentCyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.backup_outlined, color: AppTheme.primaryNavy),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.t('backup'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
                                  const Text('Disaster recovery, SHA-256 verification, and snapshot restore', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryNavy),
                              onPressed: _runBackup,
                              icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                              label: Text(l10n.t('backup_run')),
                            ),
                          ],
                        ),
                        if (_lastBackupResult != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.infoBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: AppTheme.infoBlue),
                                const SizedBox(width: 8),
                                Text(_lastBackupResult!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                        const Divider(height: 24),

                        Text('Backup Snapshots History', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        if (_backups.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: Text('No backup archives created yet.', style: TextStyle(color: Colors.grey))),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _backups.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final b = _backups[i];
                              final fileName = b['file']?.toString() ?? '';
                              final dateStr = b['created_at']?.toString() ?? '';
                              final sizeBytes = b['size'] != null ? (b['size'] as num).toInt() : 0;
                              final sizeKb = (sizeBytes / 1024).toStringAsFixed(1);

                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.archive_outlined, color: AppTheme.primaryNavy),
                                title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('$dateStr  •  $sizeKb KB'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.verified_outlined, size: 18, color: AppTheme.infoBlue),
                                      tooltip: l10n.t('backup_checksum'),
                                      onPressed: () => _verifyBackupFile(fileName),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.restore_page_outlined, size: 18, color: AppTheme.errorRed),
                                      tooltip: l10n.t('restore_run'),
                                      onPressed: () => _handleRestore(fileName),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
