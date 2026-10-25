// ignore_for_file: avoid_print
/// Generates lightweight master Lottie JSON files + manifest with 5000+ logical bindings.
/// Run: dart run tool/generate_lottie_assets.dart
library;

import 'dart:convert';
import 'dart:io';

const masterCount = 100;

const screens = [
  'splash', 'login', 'dashboard', 'pos', 'production', 'inventory', 'customers',
  'employees', 'payroll', 'reports', 'settings', 'sync_settings', 'delivery',
  'challans', 'purchasing', 'expenses', 'attendance', 'leave', 'catalog',
  'vendors', 'branches', 'terminals', 'analytics', 'accounting', 'license',
  'notifications', 'channels', 'storefront', 'customer_portal', 'equipment',
  'operator', 'sterilization', 'advanced_cycle', 'rfid_tracking', 'peripherals',
  'localization', 'business', 'global_config', 'setup_wizard', 'wizard',
  'role_editor', 'pending_invoices', 'salary_advances', 'scanner', 'sql_database',
  'dashboard_shell', 'pos_feature',
];

const roles = [
  'bg', 'empty', 'loading', 'error', 'success', 'header', 'fab', 'sync', 'offline',
  'card', 'list', 'modal', 'toast', 'badge', 'tab', 'drawer', 'toolbar', 'footer',
  'search', 'filter',
];

const variants = ['light', 'dark', 'compact', 'rtl', 'high_contrast'];

void main() {
  final root = Directory.current;
  if (!File('${root.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('Run from repository root');
    exit(1);
  }

  final mastersDir = Directory('assets/animations/masters');
  final manifestDir = Directory('assets/animations/manifest');
  mastersDir.createSync(recursive: true);
  manifestDir.createSync(recursive: true);

  final masters = <String, String>{};
  for (var i = 0; i < masterCount; i++) {
    final id = 'master_${i.toString().padLeft(3, '0')}';
    final file = 'masters/$id.json';
    masters[id] = file;
    File('assets/animations/$file').writeAsStringSync(_minimalLottie(i));
  }

  final bindings = <String, Map<String, dynamic>>{};
  for (final screen in screens) {
    for (final role in roles) {
      for (final variant in variants) {
        final logicalId = '$screen.$role.$variant';
        final masterIdx = logicalId.hashCode.abs() % masterCount;
        final masterId = 'master_${masterIdx.toString().padLeft(3, '0')}';
        bindings[logicalId] = {
          'master': masterId,
          'fit': role == 'bg' ? 'cover' : 'contain',
          'opacity': role == 'bg' ? 0.12 : 1.0,
          'repeat': !{'success', 'toast', 'error'}.contains(role),
        };
      }
    }
  }

  // Extra widget-level keys for fine-grained catalog (push over 5000).
  const widgets = [
    'primary_button', 'secondary_button', 'chip', 'avatar', 'progress',
    'skeleton', 'divider', 'icon_button', 'switch', 'checkbox',
  ];
  const states = ['idle', 'hover', 'pressed', 'disabled', 'focus'];
  for (final screen in screens) {
    for (final widget in widgets) {
      for (final state in states) {
        for (final variant in variants) {
          final logicalId = '$screen.widget.$widget.$state.$variant';
          final masterIdx = logicalId.hashCode.abs() % masterCount;
          bindings[logicalId] = {
            'master': 'master_${masterIdx.toString().padLeft(3, '0')}',
            'fit': 'contain',
            'opacity': 1.0,
            'repeat': state == 'idle',
          };
        }
      }
    }
  }

  final manifest = {
    'version': 1,
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'masters': masters,
    'bindings': bindings,
  };

  File('assets/animations/manifest/lottie_manifest.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );

  print('Masters: $masterCount');
  print('Bindings: ${bindings.length}');
}

String _minimalLottie(int seed) {
  final hue = (seed * 37) % 360;
  final r = 0.2 + (hue % 80) / 255;
  final g = 0.4 + (seed % 60) / 255;
  final b = 0.6 + (seed % 40) / 255;
  final map = {
    'v': '5.7.4',
    'fr': 24,
    'ip': 0,
    'op': 48,
    'w': 200,
    'h': 200,
    'nm': 'lp_master_$seed',
    'ddd': 0,
    'assets': [],
    'layers': [
      {
        'ddd': 0,
        'ind': 1,
        'ty': 4,
        'nm': 'pulse',
        'sr': 1,
        'ks': {
          'o': {
            'a': 1,
            'k': [
              {'t': 0, 's': [40], 'e': [90]},
              {'t': 24, 's': [90], 'e': [40]},
              {'t': 48, 's': [40]},
            ],
          },
          'r': {'a': 0, 'k': 0},
          'p': {'a': 0, 'k': [100, 100, 0]},
          'a': {'a': 0, 'k': [0, 0, 0]},
          's': {
            'a': 1,
            'k': [
              {'t': 0, 's': [80, 80, 100], 'e': [110, 110, 100]},
              {'t': 24, 's': [110, 110, 100], 'e': [80, 80, 100]},
              {'t': 48, 's': [80, 80, 100]},
            ],
          },
        },
        'ao': 0,
        'shapes': [
          {
            'ty': 'el',
            'p': {'a': 0, 'k': [0, 0]},
            's': {'a': 0, 'k': [120, 120]},
          },
          {
            'ty': 'fl',
            'c': {'a': 0, 'k': [r, g, b, 1]},
            'o': {'a': 0, 'k': 100},
          },
        ],
        'ip': 0,
        'op': 48,
        'st': 0,
        'bm': 0,
      },
    ],
  };
  return jsonEncode(map);
}
