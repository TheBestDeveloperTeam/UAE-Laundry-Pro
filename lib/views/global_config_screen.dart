import 'package:flutter/material.dart';
import 'package:laundrypro_uae/models/user_model.dart';
import 'package:laundrypro_uae/services/global_config_service.dart';

/// Standalone Global Configuration Screen — System Paths (Admin-only).
///
/// All 7 system paths (BACKUP_PATH, INVOICE_PATH, IMAGE_PATH, LOG_PATH,
/// EXPORT_PATH, TEMP_PATH, TEMPLATE_PATH) are editable here.
///
/// Access: only users with [UserModel.canEditGlobalConfig] == true.
/// Paths are persisted to C:/LaundryPro/config.json and directories
/// are auto-created on save.
class GlobalConfigScreen extends StatefulWidget {
  const GlobalConfigScreen({super.key, this.user});

  /// The currently-logged-in user. If null, read-only mode is shown.
  final UserModel? user;

  @override
  State<GlobalConfigScreen> createState() => _GlobalConfigScreenState();
}

class _GlobalConfigScreenState extends State<GlobalConfigScreen> {
  final _config = GlobalConfigService();
  final _formKey = GlobalKey<FormState>();

  // One controller per path key
  late final Map<String, TextEditingController> _controllers;

  static const _pathKeys = [
    'BACKUP_PATH',
    'INVOICE_PATH',
    'IMAGE_PATH',
    'LOG_PATH',
    'EXPORT_PATH',
    'TEMP_PATH',
    'TEMPLATE_PATH',
  ];

  static const _pathLabels = {
    'BACKUP_PATH':   'Backup Path',
    'INVOICE_PATH':  'Invoice Path',
    'IMAGE_PATH':    'Image / Document Path',
    'LOG_PATH':      'Log Path',
    'EXPORT_PATH':   'Export Path',
    'TEMP_PATH':     'Temporary Files Path',
    'TEMPLATE_PATH': 'Print Templates Path',
  };

  static const _pathIcons = {
    'BACKUP_PATH':   Icons.backup_outlined,
    'INVOICE_PATH':  Icons.receipt_long_outlined,
    'IMAGE_PATH':    Icons.image_outlined,
    'LOG_PATH':      Icons.article_outlined,
    'EXPORT_PATH':   Icons.file_download_outlined,
    'TEMP_PATH':     Icons.folder_special_outlined,
    'TEMPLATE_PATH': Icons.print_outlined,
  };

  static const _pathDescriptions = {
    'BACKUP_PATH':   'Database ZIP backups (db_YYYYMMDD_HHMMSS.zip)',
    'INVOICE_PATH':  'Generated invoice PDFs',
    'IMAGE_PATH':    'Garment photos, customer docs, product images',
    'LOG_PATH':      'App, error, hardware, print, and audit logs',
    'EXPORT_PATH':   'Report PDFs, CSV / XLSX data exports',
    'TEMP_PATH':     'Temporary processing files (auto-cleaned)',
    'TEMPLATE_PATH': 'JSON print templates (receipt, invoice, tags)',
  };

  bool _saving = false;
  final _errors = <String, String?>{};

  bool get _isReadOnly => !(widget.user?.canEditGlobalConfig ?? false);

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final key in _pathKeys)
        key: TextEditingController(text: _config.allPaths[key] ?? '')
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_isReadOnly) return;
    setState(() {
      _saving = true;
      _errors.clear();
    });

    final updates = {
      for (final key in _pathKeys)
        key: _controllers[key]!.text.trim()
    };

    final errorMap = await _config.updatePaths(updates);

    // Refresh controllers to the saved values (adds trailing slash if needed)
    for (final key in _pathKeys) {
      if (errorMap[key] == null) {
        _controllers[key]!.text = _config.allPaths[key] ?? updates[key]!;
      }
    }

    setState(() {
      _saving = false;
      _errors.addAll(errorMap);
    });

    if (!mounted) return;

    final hasError = errorMap.values.any((e) => e != null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hasError
            ? 'Some paths could not be saved — check errors below.'
            : 'Configuration saved successfully.'),
        backgroundColor: hasError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Reset ────────────────────────────────────────────────────────────────

  Future<void> _resetAll() async {
    if (_isReadOnly) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Paths to Defaults?'),
        content: const Text(
            'This will reset all paths to factory defaults:\nC:/LaundryPro/...'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed != true) return;

    await _config.resetAll();
    for (final key in _pathKeys) {
      _controllers[key]!.text = _config.allPaths[key] ?? '';
    }
    _errors.clear();
    setState(() {});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All paths reset to defaults.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _resetSingle(String key) async {
    if (_isReadOnly) return;
    await _config.resetPath(key);
    _controllers[key]!.text = _config.allPaths[key] ?? '';
    _errors.remove(key);
    setState(() {});
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Configuration — System Paths'),
        actions: [
          if (!_isReadOnly) ...[
            TextButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset All'),
              onPressed: _resetAll,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving…' : 'Save All Paths'),
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ── Admin-only banner ─────────────────────────────────────────
            _AccessBanner(isReadOnly: _isReadOnly),
            const SizedBox(height: 20),

            // ── Info card ─────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: theme.colorScheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Text('Path Configuration',
                            style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All paths are stored in C:/LaundryPro/config.json. '
                      'Directories are created automatically when a path is saved. '
                      'Trailing slashes are added automatically.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Path fields ───────────────────────────────────────────────
            ...List.generate(_pathKeys.length, (i) {
              final key = _pathKeys[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PathField(
                  pathKey: key,
                  label: _pathLabels[key]!,
                  description: _pathDescriptions[key]!,
                  icon: _pathIcons[key]!,
                  controller: _controllers[key]!,
                  error: _errors[key],
                  isReadOnly: _isReadOnly,
                  onReset: () => _resetSingle(key),
                ),
              );
            }),

            // ── Current config.json location ──────────────────────────────
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Text(
              'Config file: C:/LaundryPro/config.json',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Text(
              'Backup file naming: {BACKUP_PATH}db_YYYYMMDD_HHMMSS.zip',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _AccessBanner extends StatelessWidget {
  const _AccessBanner({required this.isReadOnly});
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    if (!isReadOnly) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          border: Border.all(color: Colors.amber.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.admin_panel_settings,
                color: Colors.amber.shade800, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Administrator Mode — Changes affect the entire system. '
                'Ensure directories are writable before saving.',
                style: TextStyle(
                    color: Colors.amber.shade900, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.grey.shade600, size: 18),
          const SizedBox(width: 8),
          Text(
            'Read-only — You do not have permission to edit system paths.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PathField extends StatelessWidget {
  const _PathField({
    required this.pathKey,
    required this.label,
    required this.description,
    required this.icon,
    required this.controller,
    required this.isReadOnly,
    required this.onReset,
    this.error,
  });

  final String pathKey;
  final String label;
  final String description;
  final IconData icon;
  final TextEditingController controller;
  final bool isReadOnly;
  final VoidCallback onReset;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = error != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label row
            Row(
              children: [
                Icon(icon,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                // Key badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    pathKey,
                    style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(description,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 10),

            // Text field
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    readOnly: isReadOnly,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g. C:/LaundryPro/backups/',
                      errorText: hasError ? error : null,
                      prefixIcon:
                          const Icon(Icons.folder_outlined, size: 18),
                      suffixIcon: isReadOnly
                          ? const Icon(Icons.lock_outline, size: 16)
                          : null,
                    ),
                  ),
                ),
                if (!isReadOnly) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Reset to default',
                    child: IconButton.outlined(
                      icon: const Icon(Icons.restart_alt, size: 18),
                      onPressed: onReset,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
