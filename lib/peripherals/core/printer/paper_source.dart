/// Represents one paper tray / input source advertised by the Windows
/// printer driver via `System.Drawing.Printing.PrinterSettings.PaperSources`.
class PaperSourceModel {
  PaperSourceModel({
    required this.kind,
    required this.rawKind,
    required this.sourceName,
  });

  /// Friendly name from .NET `PaperSourceKind` enum (e.g. `AutomaticFeed`,
  /// `Cassette`, `TopBin`, `Manual`).
  final String kind;

  /// Numeric source identifier (driver-specific).
  final int rawKind;

  /// Localized driver-provided name (e.g. `Tray 1`, `Manual Feed`).
  final String sourceName;

  factory PaperSourceModel.fromMap(Map<String, dynamic> map) {
    return PaperSourceModel(
      kind: (map['Kind'] ?? '').toString(),
      rawKind: (map['RawKind'] is int)
          ? map['RawKind'] as int
          : int.tryParse(map['RawKind']?.toString() ?? '') ?? 0,
      sourceName: (map['SourceName'] ?? '').toString(),
    );
  }

  String get displayLabel {
    final name = sourceName.trim();
    if (name.isEmpty) return kind.isEmpty ? 'Default' : kind;
    if (kind.isEmpty || kind == name) return name;
    return '$name ($kind)';
  }
}
