import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/peripherals/core/printer/paper_size.dart';
import 'package:laundrypro_uae/peripherals/core/printer/rich_line_formatter.dart';

void main() {
  group('RichLineFormatter', () {
    final formatter = RichLineFormatter(paper: PaperSize.thermal80mm);

    test('plain text uses left alignment', () {
      final bytes = formatter.formatLine('hello');
      // ESC a 0  → 1B 61 00
      expect(bytes.take(3).toList(), [0x1B, 0x61, 0x00]);
      // payload ends with newline
      expect(bytes.last, 0x0A);
    });

    test('center tag emits ESC a 1', () {
      final bytes = formatter.formatLine('[C]centered[/C]');
      expect(bytes.take(3).toList(), [0x1B, 0x61, 0x01]);
    });

    test('right tag emits ESC a 2', () {
      final bytes = formatter.formatLine('[R]right[/R]');
      expect(bytes.take(3).toList(), [0x1B, 0x61, 0x02]);
    });

    test('bold tag wraps payload with ESC E 1 / ESC E 0', () {
      final bytes = formatter.formatLine('[B]bold[/B]');
      expect(bytes.contains(0x1B), true);
      // Look for 1B 45 01 in sequence
      var found = false;
      for (var i = 0; i < bytes.length - 2; i++) {
        if (bytes[i] == 0x1B && bytes[i + 1] == 0x45 && bytes[i + 2] == 0x01) {
          found = true;
          break;
        }
      }
      expect(found, true);
    });

    test('BIG tag emits GS ! 0x11', () {
      final bytes = formatter.formatLine('[BIG]big[/BIG]');
      var found = false;
      for (var i = 0; i < bytes.length - 2; i++) {
        if (bytes[i] == 0x1D && bytes[i + 1] == 0x21 && bytes[i + 2] == 0x11) {
          found = true;
          break;
        }
      }
      expect(found, true);
    });

    test('HR emits paper-width separator', () {
      final bytes = formatter.formatLine('[HR]');
      // 32 dashes for 58mm, 48 for 80mm. We're on 80mm.
      final dashCount = bytes.where((b) => b == 0x2D).length;
      expect(dashCount, PaperSize.thermal80mm.columns);
    });

    test('FEED:n emits ESC d n', () {
      final bytes = formatter.formatLine('[FEED:3]');
      expect(bytes, [0x1B, 0x64, 0x03]);
    });

    test('QR builds full ESC/POS QR command block', () {
      final bytes = formatter.formatLine('[QR]hello[/QR]');
      // Should include 1D 28 6B sequences for model/size/EC/store/print.
      var sequences = 0;
      for (var i = 0; i < bytes.length - 2; i++) {
        if (bytes[i] == 0x1D && bytes[i + 1] == 0x28 && bytes[i + 2] == 0x6B) {
          sequences++;
        }
      }
      expect(sequences >= 4, true);
    });

    test('barcode emits Code128 sequence', () {
      final bytes = formatter.formatLine('[BC]ABC123[/BC]');
      var found = false;
      for (var i = 0; i < bytes.length - 1; i++) {
        if (bytes[i] == 0x1D && bytes[i + 1] == 0x6B) {
          found = true;
          break;
        }
      }
      expect(found, true);
    });
  });
}
