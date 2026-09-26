class CartLine {
  CartLine({
    required this.itemType,
    required this.itemId,
    required this.name,
    required this.rate,
    this.quantity = 1,
    this.discount = 0.0,
    this.modifiers = const [],
    this.vatRate = 0.05,
  });

  final String itemType;
  final int itemId;
  final String name;
  double rate;
  int quantity;
  double discount;
  List<Map<String, dynamic>> modifiers;
  double vatRate;

  double get modifierTotal {
    double total = 0.0;
    for (final m in modifiers) {
      final type = m['price_type']?.toString() ?? 'fixed';
      final val = double.tryParse(m['price_value']?.toString() ?? '0') ?? 0.0;
      if (type == 'percentage') {
        total += (rate * (val / 100.0));
      } else {
        total += val;
      }
    }
    return total;
  }

  double get unitRateWithModifiers => rate + modifierTotal;

  double get lineSubtotal => unitRateWithModifiers * quantity;

  double get lineTotal => (lineSubtotal - discount).clamp(0.0, double.infinity);

  double get vatAmount => lineTotal * vatRate;

  double get lineTotalWithVat => lineTotal + vatAmount;

  Map<String, dynamic> toLine() => {
        'item_type': itemType,
        'item_id': itemId,
        'description': name,
        'quantity': quantity,
        'rate': unitRateWithModifiers,
        'discount': discount,
        'modifiers': modifiers,
      };
}
