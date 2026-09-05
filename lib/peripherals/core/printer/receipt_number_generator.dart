import 'dart:math';

/// Unique receipt identifiers encoded for QR (ISO/IEC 18004), Code128 (GS1-128
/// subset B), and EAN-13 (GS1 GTIN check digit).
class ReceiptVerificationCodes {
  ReceiptVerificationCodes({
    required this.receiptNumber,
    required this.qrPayload,
    required this.code128Payload,
    required this.ean13,
  });

  /// Human-readable id, e.g. `RCP-20260521-143052-8F3A`.
  final String receiptNumber;

  /// QR content (UTF-8); verification URL or `RCP:` URI for scanners/apps.
  final String qrPayload;

  /// Code128 / BC tag payload (ASCII subset B).
  final String code128Payload;

  /// Exactly 13 digits with valid GS1 mod-10 check digit.
  final String ean13;

  /// Generates a new unique receipt number and scannable encodings.
  factory ReceiptVerificationCodes.generate({
    String verifyBaseUrl = 'https://receipt.verify',
    Random? random,
  }) {
    final rng = random ?? Random.secure();
    final now = DateTime.now().toUtc();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    final suffix = rng.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0').toUpperCase();

    final receiptNumber = 'RCP-$y$m$d-$h$min$s-$suffix';
    final compact = receiptNumber.replaceAll(RegExp(r'[^A-Z0-9]'), '');

    final base = verifyBaseUrl.endsWith('/')
        ? verifyBaseUrl.substring(0, verifyBaseUrl.length - 1)
        : verifyBaseUrl;
    final qrPayload = '$base?id=$receiptNumber';

    final code128Payload = compact.length <= 80 ? compact : compact.substring(0, 80);

    final ean13 = _ean13FromReceipt(receiptNumber, rng);

    return ReceiptVerificationCodes(
      receiptNumber: receiptNumber,
      qrPayload: qrPayload,
      code128Payload: code128Payload,
      ean13: ean13,
    );
  }

  /// GS1 mod-10 check digit for 12-digit string.
  static int gs1CheckDigit(String twelveDigits) {
    if (twelveDigits.length != 12 || !RegExp(r'^\d{12}$').hasMatch(twelveDigits)) {
      throw ArgumentError('EAN-13 requires exactly 12 numeric digits before check digit.');
    }
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      final digit = twelveDigits.codeUnitAt(11 - i) - 48;
      sum += (i.isEven) ? digit * 3 : digit;
    }
    return (10 - (sum % 10)) % 10;
  }

  /// Internal-use EAN-13 (prefix 2) derived from receipt id + time.
  static String _ean13FromReceipt(String receiptNumber, Random rng) {
    final hash = receiptNumber.hashCode.abs() % 1000000;
    final tail = (DateTime.now().millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
    final middle = hash.toString().padLeft(6, '0').substring(0, 6);
    final twelve = '2$middle$tail'.substring(0, 12);
    final check = gs1CheckDigit(twelve);
    return '$twelve$check';
  }
}
