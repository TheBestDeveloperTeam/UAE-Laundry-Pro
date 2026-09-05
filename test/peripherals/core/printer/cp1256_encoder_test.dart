import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/peripherals/core/printer/arabic_text.dart';
import 'package:laundrypro_uae/peripherals/core/printer/cp1256_encoder.dart';

void main() {
  group('Cp1256Encoder', () {
    test('detects Arabic vs Latin', () {
      expect(Cp1256Encoder.containsArabic('Hello'), false);
      expect(Cp1256Encoder.containsArabic('مرحبا'), true);
      expect(Cp1256Encoder.containsArabic('Hello مرحبا'), true);
    });

    test('encodes ASCII unchanged', () {
      expect(Cp1256Encoder.encode('ABC'), const [0x41, 0x42, 0x43]);
    });

    test('maps known Arabic letters to expected CP1256 bytes', () {
      expect(Cp1256Encoder.encode('ا'), const [0xC7]);
      expect(Cp1256Encoder.encode('ب'), const [0xC8]);
      expect(Cp1256Encoder.encode('ل'), const [0xE1]);
      expect(Cp1256Encoder.encode('م'), const [0xE3]);
    });

    test('encodes an Arabic word', () {
      // م ر ح ب ا → 0xE3 0xD1 0xCD 0xC8 0xC7
      expect(
        Cp1256Encoder.encode('مرحبا'),
        const [0xE3, 0xD1, 0xCD, 0xC8, 0xC7],
      );
    });

    test('unmapped codepoints fall back to ?', () {
      // U+4E2D is CJK '中' which has no CP1256 mapping.
      expect(Cp1256Encoder.encode('中'), const [0x3F]);
    });
  });

  group('ArabicText.reverseRtlRuns', () {
    test('keeps pure Latin unchanged', () {
      expect(ArabicText.reverseRtlRuns('Hello World'), 'Hello World');
    });

    test('reverses a pure Arabic word', () {
      // 'مرحبا' codepoints: م ر ح ب ا → reversed: ا ب ح ر م
      expect(ArabicText.reverseRtlRuns('مرحبا'), 'ابحرم');
    });

    test('reverses only the Arabic run in mixed text', () {
      expect(
        ArabicText.reverseRtlRuns('Hello مرحبا World'),
        'Hello ابحرم World',
      );
    });

    test('keeps spaces inside Arabic run', () {
      // 'كلمة أخرى' → keep the internal space within the reversed Arabic run
      final reversed = ArabicText.reverseRtlRuns('كلمة أخرى');
      // The full sequence is Arabic + space + Arabic, so the whole run
      // reverses to a single contiguous Arabic block.
      expect(Cp1256Encoder.containsArabic(reversed), true);
      expect(reversed.length, 'كلمة أخرى'.length);
    });
  });
}
