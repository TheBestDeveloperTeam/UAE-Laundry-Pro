import 'dart:convert';

import 'package:flutter/services.dart';

class LottieBinding {
  const LottieBinding({
    required this.assetPath,
    required this.fit,
    required this.opacity,
    required this.repeat,
  });

  final String assetPath;
  final String fit;
  final double opacity;
  final bool repeat;
}

/// Resolves logical animation IDs to master asset paths (manifest-tier catalog).
class LottieCatalog {
  LottieCatalog._();

  static LottieCatalog? _instance;
  static LottieCatalog get instance => _instance ??= LottieCatalog._();

  Map<String, String>? _masters;
  Map<String, dynamic>? _bindings;
  bool _loaded = false;

  static const String manifestAsset = 'assets/animations/manifest/lottie_manifest.json';

  Future<void> ensureLoaded() async {
    if (_loaded) {
      return;
    }
    final raw = await rootBundle.loadString(manifestAsset);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _masters = (json['masters'] as Map).map(
      (k, v) => MapEntry(k.toString(), 'assets/animations/${v.toString()}'),
    );
    _bindings = Map<String, dynamic>.from(json['bindings'] as Map);
    _loaded = true;
  }

  int bindingCount() => _bindings?.length ?? 0;

  LottieBinding? resolve(String logicalId) {
    if (_bindings == null || _masters == null) {
      return null;
    }
    final entry = _bindings![logicalId];
    if (entry is! Map) {
      return null;
    }
    final masterKey = entry['master']?.toString();
    if (masterKey == null) {
      return null;
    }
    final path = _masters![masterKey];
    if (path == null) {
      return null;
    }
    return LottieBinding(
      assetPath: path,
      fit: entry['fit']?.toString() ?? 'contain',
      opacity: (entry['opacity'] as num?)?.toDouble() ?? 1.0,
      repeat: entry['repeat'] as bool? ?? true,
    );
  }

  /// For tests: load from JSON string.
  void loadFromJsonString(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _masters = (json['masters'] as Map).map(
      (k, v) => MapEntry(k.toString(), 'assets/animations/${v.toString()}'),
    );
    _bindings = Map<String, dynamic>.from(json['bindings'] as Map);
    _loaded = true;
  }
}
