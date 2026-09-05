import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/peripherals/core/printer/paper_size.dart';
import 'package:laundrypro_uae/peripherals/core/printer/rich_line_formatter.dart';

void main() {
  group('RichLineFormatter Arabic path', () {
    final formatter = RichLineFormatter(paper: PaperSize.thermal80mm);

    int indexOfEscT(List<int> bytes, {int from = 0}) {
      for (var i = from; i < bytes.length - 2; i++) {
        if (bytes[i] == 0x1B && bytes[i + 1] == 0x74) {
          return i;
        }
      }
      return -1;
    }

    test('emits ESC t n for Arabic line and restores default', () {
      final bytes = formatter.formatLine('مرحبا');
      final first = indexOfEscT(bytes);
      expect(first, isNonNegative);
      // The third byte after the first ESC t is the Arabic code page.
      expect(bytes[first + 2], 32);

      // A second ESC t should restore the default code page (0).
      final second = indexOfEscT(bytes, from: first + 3);
      expect(second, isNonNegative);
      expect(bytes[second + 2], 0);
    });

    test('Latin line keeps UTF-8 path (no ESC t)', () {
      final bytes = formatter.formatLine('Hello world');
      expect(indexOfEscT(bytes), -1);
    });

    test('mixed line switches to Arabic code page', () {
      final bytes = formatter.formatLine('Total: 100 ريال');
      expect(indexOfEscT(bytes), isNonNegative);
    });

    test('configurable code page is respected', () {
      final custom = RichLineFormatter(
        paper: PaperSize.thermal80mm,
        arabicCodePage: 22,
      );
      final bytes = custom.formatLine('مرحبا');
      final idx = indexOfEscT(bytes);
      expect(bytes[idx + 2], 22);
    });
  });
}
