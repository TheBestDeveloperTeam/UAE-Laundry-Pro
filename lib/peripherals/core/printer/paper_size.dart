/// Logical paper formats supported by the printer engine. The column count
/// drives ESC/POS line widths for separators and aligned text rendering.
enum PaperSize {
  thermal58mm(id: 'thermal58', columns: 32, label: '58mm Thermal'),
  thermal80mm(id: 'thermal80', columns: 48, label: '80mm Thermal'),
  a6(id: 'a6', columns: 64, label: 'A6'),
  a5(id: 'a5', columns: 72, label: 'A5'),
  a4(id: 'a4', columns: 80, label: 'A4');

  const PaperSize({
    required this.id,
    required this.columns,
    required this.label,
  });

  final String id;
  final int columns;
  final String label;

  static PaperSize fromId(String? id) {
    if (id == null) return PaperSize.thermal80mm;
    return PaperSize.values.firstWhere(
      (size) => size.id == id,
      orElse: () => PaperSize.thermal80mm,
    );
  }
}
