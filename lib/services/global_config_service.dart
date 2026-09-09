import 'dart:convert';
import 'dart:io';

/// Singleton service for standalone global path configuration.
///
/// Paths are persisted to [_configFilePath] (C:/LaundryPro/config.json).
/// All directories are auto-created on init and on path update.
/// Admin-only writes: enforce at UI layer via UserModel.hasPermission.
class GlobalConfigService {
  static final GlobalConfigService _instance = GlobalConfigService._internal();
  factory GlobalConfigService() => _instance;
  GlobalConfigService._internal();

  static const String _configFilePath = 'C:/LaundryPro/config.json';

  // Default values — used on first install or missing keys.
  static const Map<String, String> _defaults = {
    'BACKUP_PATH':   'C:/LaundryPro/backups/',
    'INVOICE_PATH':  'C:/LaundryPro/invoices/',
    'IMAGE_PATH':    'C:/LaundryPro/images/',
    'LOG_PATH':      'C:/LaundryPro/logs/',
    'EXPORT_PATH':   'C:/LaundryPro/exports/',
    'TEMP_PATH':     'C:/LaundryPro/temp/',
    'TEMPLATE_PATH': 'C:/LaundryPro/templates/',
  };

  Map<String, String> _paths = Map.from(_defaults);
  bool _initialized = false;

  // ─── Initialisation ──────────────────────────────────────────────────────

  /// Call once from main() before runApp().
  Future<void> init() async {
    if (_initialized) return;
    await _load();
    await _ensureDirectoriesExist();
    _initialized = true;
  }

  Future<void> _load() async {
    final file = File(_configFilePath);
    if (!await file.exists()) {
      await _save();
      return;
    }
    try {
      final raw = await file.readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final loaded = (json['paths'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v.toString()));
      // Merge: keep defaults for any missing key
      _paths = {..._defaults, ...loaded};
    } catch (_) {
      // Corrupted config — reset to defaults and overwrite.
      _paths = Map.from(_defaults);
      await _save();
    }
  }

  // ─── Path Getters ─────────────────────────────────────────────────────────

  String get backupPath   => _paths['BACKUP_PATH']!;
  String get invoicePath  => _paths['INVOICE_PATH']!;
  String get imagePath    => _paths['IMAGE_PATH']!;
  String get logPath      => _paths['LOG_PATH']!;
  String get exportPath   => _paths['EXPORT_PATH']!;
  String get tempPath     => _paths['TEMP_PATH']!;
  String get templatePath => _paths['TEMPLATE_PATH']!;

  /// Returns a copy of all current path values.
  Map<String, String> get allPaths => Map.unmodifiable(_paths);

  // ─── Validation ───────────────────────────────────────────────────────────

  /// Returns an error message if [path] is invalid/unwritable, or null if OK.
  Future<String?> validatePath(String path) async {
    if (path.trim().isEmpty) return 'Path cannot be empty.';
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      // Write probe
      final probe = File('${dir.path}/.write_probe');
      await probe.writeAsString('ok');
      await probe.delete();
      return null;
    } catch (e) {
      return 'Path is not writable: $path';
    }
  }

  // ─── Updates ──────────────────────────────────────────────────────────────

  /// Update a single path key (e.g. 'BACKUP_PATH').
  /// Returns null on success, or an error message on failure.
  Future<String?> updatePath(String key, String newPath) async {
    if (!_defaults.containsKey(key)) return 'Unknown config key: $key';
    final error = await validatePath(newPath);
    if (error != null) return error;
    _paths[key] = newPath.endsWith('/') ? newPath : '$newPath/';
    await _save();
    return null;
  }

  /// Update multiple paths atomically.
  Future<Map<String, String?>> updatePaths(Map<String, String> updates) async {
    final errors = <String, String?>{};
    final valid = <String, String>{};
    for (final entry in updates.entries) {
      final error = await validatePath(entry.value);
      if (error != null) {
        errors[entry.key] = error;
      } else {
        valid[entry.key] = entry.value.endsWith('/')
            ? entry.value
            : '${entry.value}/';
        errors[entry.key] = null;
      }
    }
    // Only apply entries with no error
    for (final entry in valid.entries) {
      if (_defaults.containsKey(entry.key)) {
        _paths[entry.key] = entry.value;
      }
    }
    if (valid.isNotEmpty) await _save();
    return errors;
  }

  /// Reset a single path to its factory default.
  Future<void> resetPath(String key) async {
    if (_defaults.containsKey(key)) {
      _paths[key] = _defaults[key]!;
      await _save();
      await _ensureDirectoriesExist();
    }
  }

  /// Reset all paths to factory defaults.
  Future<void> resetAll() async {
    _paths = Map.from(_defaults);
    await _save();
    await _ensureDirectoriesExist();
  }

  // ─── Persistence ──────────────────────────────────────────────────────────

  Future<void> _save() async {
    final file = File(_configFilePath);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    final content = const JsonEncoder.withIndent('  ').convert({'paths': _paths});
    await file.writeAsString(content);
  }

  Future<void> _ensureDirectoriesExist() async {
    for (final path in _paths.values) {
      final dir = Directory(path);
      if (!await dir.exists()) {
        try {
          await dir.create(recursive: true);
        } catch (_) {
          // Non-fatal: logged at startup, user can fix via admin UI.
        }
      }
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Returns the backup filename for the current timestamp.
  /// e.g.  C:/LaundryPro/backups/db_20261001_020000.zip
  String backupFileName() {
    final now = DateTime.now();
    final stamp =
        '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    return '${backupPath}db_$stamp.zip';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
