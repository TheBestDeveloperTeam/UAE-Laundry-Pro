import 'package:laundrypro_uae/peripherals/core/printer/cp1256_encoder.dart';

/// Lightweight bidirectional helper for ESC/POS Arabic printing.
///
/// Most thermal printers print bytes strictly left-to-right and rely on the
/// host to feed Arabic runs in **visual** order (right-to-left bytes appear
/// rightmost on paper). This helper walks the string and reverses each
/// Arabic run while leaving Latin/digit runs in their natural order — which
/// matches the most common ESC/POS Arabic firmware behaviour.
class ArabicText {
  ArabicText._();

  /// Reverses each contiguous Arabic run in [text]. Embedded spaces between
  /// Arabic characters are kept inside the run so they reverse with the rest
  /// of the run (so `"كلمة أخرى"` remains visually contiguous after
  /// reversal). Non-Arabic runs pass through unchanged.
  static String reverseRtlRuns(String text) {
    if (text.isEmpty) return text;
    final chars = text.runes.toList();
    final out = StringBuffer();
    var i = 0;
    while (i < chars.length) {
      if (Cp1256Encoder.isArabicChar(chars[i])) {
        var j = i + 1;
        while (j < chars.length) {
          final c = chars[j];
          final isArabic = Cp1256Encoder.isArabicChar(c);
          final isInternalSpace = c == 0x20 &&
              j + 1 < chars.length &&
              Cp1256Encoder.isArabicChar(chars[j + 1]);
          if (!isArabic && !isInternalSpace) break;
          j++;
        }
        for (var k = j - 1; k >= i; k--) {
          out.writeCharCode(chars[k]);
        }
        i = j;
      } else {
        out.writeCharCode(chars[i]);
        i++;
      }
    }
    return out.toString();
  }
}
