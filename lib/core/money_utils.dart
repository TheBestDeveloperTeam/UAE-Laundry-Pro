class MoneyUtils {
  /// Rounds a monetary amount to 2 decimal places using ROUND_HALF_UP strategy.
  static double roundHalfUp(double amount) {
    return (amount * 100).roundToDouble() / 100;
  }

  /// Calculates the 5% VAT portion for an inclusive total.
  static double calculateVatInclusive(double totalAmount, {double rate = 0.05}) {
    return roundHalfUp(totalAmount - (totalAmount / (1 + rate)));
  }

  /// Calculates the 5% VAT portion for an exclusive subtotal.
  static double calculateVatExclusive(double subtotal, {double rate = 0.05}) {
    return roundHalfUp(subtotal * rate);
  }

  /// Returns the total price including VAT given an exclusive subtotal.
  static double addVat(double subtotal, {double rate = 0.05}) {
    return roundHalfUp(subtotal * (1 + rate));
  }
}
