class ScaleReading {
  ScaleReading({
    required this.weight,
    required this.unit,
    required this.stable,
    required this.rawPacket,
    required this.hexPacket,
    required this.timestamp,
  });

  final String weight;
  final String unit;
  final bool stable;
  final String rawPacket;
  final String hexPacket;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'deviceName': 'GenericScale',
        'weight': weight,
        'unit': unit,
        'stable': stable,
        'rawPacket': rawPacket,
        'hexPacket': hexPacket,
        'timestamp': timestamp.toIso8601String(),
      };
}

class ScaleParser {
  ScaleReading parse(List<int> bytes) {
    final raw = String.fromCharCodes(bytes).trim();
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    final sanitized = raw.replaceAll(RegExp(r'[^0-9A-Za-z\.\-\s]'), '');
    final stable = sanitized.contains('ST') || sanitized.contains('stable');
    final match = RegExp(r'(-?\d+(?:\.\d+)?)\s*(kg|g|lb|oz)?', caseSensitive: false).firstMatch(sanitized);
    final weight = match?.group(1) ?? '0';
    final unit = (match?.group(2) ?? 'kg').toLowerCase();

    return ScaleReading(
      weight: weight,
      unit: unit,
      stable: stable,
      rawPacket: raw,
      hexPacket: hex,
      timestamp: DateTime.now().toUtc(),
    );
  }
}
