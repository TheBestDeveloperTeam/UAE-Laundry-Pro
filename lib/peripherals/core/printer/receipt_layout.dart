/// Monospace column layout helpers for thermal receipt lines.
class ReceiptLayout {
  ReceiptLayout._();

  static String clip(String value, int maxChars) {
    if (maxChars <= 0) return '';
    if (value.length <= maxChars) return value;
    return value.substring(0, maxChars);
  }

  /// Left label and right value on one row (prices, totals).
  static String leftRight({
    required String left,
    required String right,
    required int columns,
  }) {
    final r = clip(right, columns ~/ 2);
    final leftMax = (columns - r.length - 1).clamp(1, columns - 1);
    final l = clip(left, leftMax);
    return l.padRight(columns - r.length) + r;
  }

  /// Item table row: name (left), qty (center), amount (right).
  static String itemRow({
    required String name,
    required String qty,
    required String amount,
    required int columns,
  }) {
    const amountCol = 10;
    const qtyCol = 4;
    final nameCol = (columns - amountCol - qtyCol).clamp(8, columns - 14);
    final n = clip(name, nameCol).padRight(nameCol);
    final q = clip(qty, qtyCol).padLeft(qtyCol);
    final a = clip(amount, amountCol).padLeft(amountCol);
    return '$n$q$a';
  }
}
