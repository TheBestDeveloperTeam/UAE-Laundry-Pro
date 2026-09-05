import 'dart:convert';

import 'package:laundrypro_uae/peripherals/core/printer/arabic_text.dart';
import 'package:laundrypro_uae/peripherals/core/printer/cp1256_encoder.dart';
import 'package:laundrypro_uae/peripherals/core/printer/paper_size.dart';
import 'package:laundrypro_uae/peripherals/core/printer/receipt_layout.dart';

/// Parses inline markup tags inside custom receipt lines and emits the
/// corresponding ESC/POS byte sequences.
///
/// Supported markup (case-insensitive):
///   `[C]text[/C]`    center align
///   `[R]text[/R]`    right align
///   `[B]text[/B]`    bold
///   `[BIG]text[/BIG]` double-width + double-height
///   `[QR]content[/QR]` QR code (whole line becomes a QR)
///   `[BC]content[/BC]` Code128 barcode (whole line)
///   `[EAN13]digits[/EAN13]` EAN-13 barcode (13 digits)
///   `[BI]english|arabic[/BI]` bilingual stacked (EN line, AR below, centered)
///   `[L][BI]en|ar[/BI][/L]` bilingual stacked, left-aligned
///   `[C][BI]en|ar[/BI][/C]` bilingual stacked, centered
///   `[LR]label|value[/LR]` left label, right value (prices)
///   `[R3]name|qty|amount[/R3]` three-column row (item table)
///   `[HR]`            horizontal rule (full paper width)
///   `[FEED:n]`        feed N lines (1..16)
///
/// Tags can combine (alignment + bold + big). QR/BC/HR/FEED occupy the
/// entire line by themselves.
class RichLineFormatter {
  RichLineFormatter({
    required this.paper,
    this.arabicCodePage = 32,
    this.defaultCodePage = 0,
    this.reverseArabicRtl = true,
  });

  final PaperSize paper;

  /// ESC/POS code page id selected via `ESC t n` when Arabic text is
  /// detected on a line. 32 (`WPC1256`) is the most widely supported value
  /// across Chinese-built thermal printers and modern Epson firmware.
  /// Common alternatives: 22 (PC864), 39, 41.
  final int arabicCodePage;

  /// Code page to restore via `ESC t n` after an Arabic line. 0 (`PC437`)
  /// is the universal default.
  final int defaultCodePage;

  /// When true, Arabic runs are visually reversed before being sent so they
  /// read right-to-left on paper. Most ESC/POS firmware expects this.
  final bool reverseArabicRtl;

  static const List<int> _alignLeft = <int>[0x1B, 0x61, 0x00];
  static const List<int> _alignCenter = <int>[0x1B, 0x61, 0x01];
  static const List<int> _alignRight = <int>[0x1B, 0x61, 0x02];
  static const List<int> _boldOn = <int>[0x1B, 0x45, 0x01];
  static const List<int> _boldOff = <int>[0x1B, 0x45, 0x00];
  static const List<int> _sizeBig = <int>[0x1D, 0x21, 0x11];
  static const List<int> _sizeNormal = <int>[0x1D, 0x21, 0x00];

  List<int> formatLine(String rawLine) {
    final out = <int>[];
    var line = rawLine;

    if (line.trim().toUpperCase() == '[HR]') {
      out.addAll(_alignLeft);
      out.addAll(utf8.encode('${'-' * paper.columns}\n'));
      return out;
    }

    final feed = RegExp(
      r'^\s*\[FEED:(\d+)\]\s*$',
      caseSensitive: false,
    ).firstMatch(line);
    if (feed != null) {
      final n = int.parse(feed.group(1)!).clamp(1, 16);
      out.addAll(<int>[0x1B, 0x64, n]);
      return out;
    }

    final qr = RegExp(
      r'^\s*\[QR\](.+?)\[/QR\]\s*$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(line);
    if (qr != null) {
      out.addAll(_alignCenter);
      out.addAll(buildQrCode(qr.group(1)!));
      out.addAll(<int>[0x0A]);
      return out;
    }

    final bc = RegExp(
      r'^\s*\[BC\](.+?)\[/BC\]\s*$',
      caseSensitive: false,
    ).firstMatch(line);
    if (bc != null) {
      out.addAll(_alignCenter);
      out.addAll(buildCode128(bc.group(1)!));
      out.addAll(<int>[0x0A]);
      return out;
    }

    final ean = RegExp(
      r'^\s*\[EAN13\](\d{13})\[/EAN13\]\s*$',
      caseSensitive: false,
    ).firstMatch(line);
    if (ean != null) {
      out.addAll(_alignCenter);
      out.addAll(buildEan13(ean.group(1)!));
      out.addAll(<int>[0x0A]);
      return out;
    }

    final lr = RegExp(
      r'^\s*\[LR\](.+?)\|(.+?)\[/LR\]\s*$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(line);
    if (lr != null) {
      out.addAll(_alignLeft);
      final row = ReceiptLayout.leftRight(
        left: lr.group(1)!.trim(),
        right: lr.group(2)!.trim(),
        columns: paper.columns,
      );
      out.addAll(_encodeContent(row));
      return out;
    }

    final r3 = RegExp(
      r'^\s*\[R3\](.*?)\|(.*?)\|(.*?)\[/R3\]\s*$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(line);
    if (r3 != null) {
      out.addAll(_alignLeft);
      final row = ReceiptLayout.itemRow(
        name: r3.group(1)!.trim(),
        qty: r3.group(2)!.trim(),
        amount: r3.group(3)!.trim(),
        columns: paper.columns,
      );
      out.addAll(_encodeContent(row));
      return out;
    }

    final bilingualLeft = RegExp(
      r'^\s*\[L\]\s*\[BI\](.+?)\|(.+?)\[/BI\]\s*(?:\[/L\])?\s*$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(line);
    if (bilingualLeft != null) {
      out.addAll(_alignLeft);
      final en = bilingualLeft.group(1)!.trim();
      final ar = bilingualLeft.group(2)!.trim();
      out.addAll(_encodeContent(en, trailingNewline: true));
      out.addAll(_encodeContent(ar, trailingNewline: true));
      return out;
    }

    final bilingualCenter = RegExp(
      r'^\s*\[C\]\s*\[BI\](.+?)\|(.+?)\[/BI\]\s*(?:\[/C\])?\s*$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(line);
    if (bilingualCenter != null) {
      out.addAll(_alignCenter);
      final en = bilingualCenter.group(1)!.trim();
      final ar = bilingualCenter.group(2)!.trim();
      out.addAll(_encodeContent(en, trailingNewline: true));
      out.addAll(_encodeContent(ar, trailingNewline: true));
      return out;
    }

    final bilingual = RegExp(
      r'^\s*\[BI\](.+?)\|(.+?)\[/BI\]\s*$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(line);
    if (bilingual != null) {
      out.addAll(_alignCenter);
      final en = bilingual.group(1)!.trim();
      final ar = bilingual.group(2)!.trim();
      out.addAll(_encodeContent(en, trailingNewline: true));
      out.addAll(_encodeContent(ar, trailingNewline: true));
      return out;
    }

    var alignment = _alignLeft;
    final center = RegExp(
      r'^\s*\[C\](.*)\[/C\]\s*$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(line);
    if (center != null) {
      alignment = _alignCenter;
      line = center.group(1)!;
    } else {
      final right = RegExp(
        r'^\s*\[R\](.*)\[/R\]\s*$',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(line);
      if (right != null) {
        alignment = _alignRight;
        line = right.group(1)!;
      } else {
        final leftWrap = RegExp(
          r'^\s*\[L\](.*)\[/L\]\s*$',
          caseSensitive: false,
          dotAll: true,
        ).firstMatch(line);
        if (leftWrap != null) {
          alignment = _alignLeft;
          line = leftWrap.group(1)!;
        }
      }
    }

    var bold = false;
    final boldMatch = RegExp(
      r'^\s*\[B\](.*)\[/B\]\s*$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(line);
    if (boldMatch != null) {
      bold = true;
      line = boldMatch.group(1)!;
    }

    var big = false;
    final bigMatch = RegExp(
      r'^\s*\[BIG\](.*)\[/BIG\]\s*$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(line);
    if (bigMatch != null) {
      big = true;
      line = bigMatch.group(1)!;
    }

    out.addAll(alignment);
    if (bold) out.addAll(_boldOn);
    if (big) out.addAll(_sizeBig);
    out.addAll(_encodeContent(line));
    if (big) out.addAll(_sizeNormal);
    if (bold) out.addAll(_boldOff);
    return out;
  }

  /// Encodes text; switches code page for Arabic segments.
  List<int> _encodeContent(
    String content, {
    bool trailingNewline = true,
  }) {
    if (!Cp1256Encoder.containsArabic(content)) {
      final bytes = utf8.encode(content);
      if (trailingNewline) {
        return <int>[...bytes, 0x0A];
      }
      return bytes;
    }
    final prepared =
        reverseArabicRtl ? ArabicText.reverseRtlRuns(content) : content;
    final out = <int>[];
    out.addAll(<int>[0x1B, 0x74, arabicCodePage.clamp(0, 255)]);
    out.addAll(Cp1256Encoder.encode(prepared));
    if (trailingNewline) out.add(0x0A);
    out.addAll(<int>[0x1B, 0x74, defaultCodePage.clamp(0, 255)]);
    return out;
  }

  /// EAN-13 barcode (GS k type 67 / 0x43). Requires exactly 13 digits.
  static List<int> buildEan13(String digits) {
    final code = digits.replaceAll(RegExp(r'\D'), '');
    final payload = code.length >= 13 ? code.substring(0, 13) : code.padRight(13, '0');
    final out = <int>[];
    out.addAll(<int>[0x1D, 0x68, 80]);
    out.addAll(<int>[0x1D, 0x77, 2]);
    out.addAll(<int>[0x1D, 0x48, 0x02]);
    out.addAll(<int>[0x1D, 0x6B, 0x43, 13]);
    out.addAll(utf8.encode(payload));
    return out;
  }

  static List<int> buildQrCode(
    String content, {
    int moduleSize = 6,
    int errorLevel = 48, // 48..51 -> L, M, Q, H
  }) {
    final data = utf8.encode(content);
    final out = <int>[];
    out.addAll(
      <int>[0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00],
    );
    out.addAll(<int>[
      0x1D,
      0x28,
      0x6B,
      0x03,
      0x00,
      0x31,
      0x43,
      moduleSize.clamp(1, 16),
    ]);
    out.addAll(<int>[
      0x1D,
      0x28,
      0x6B,
      0x03,
      0x00,
      0x31,
      0x45,
      errorLevel.clamp(48, 51),
    ]);
    final len = data.length + 3;
    out.addAll(<int>[
      0x1D,
      0x28,
      0x6B,
      len & 0xFF,
      (len >> 8) & 0xFF,
      0x31,
      0x50,
      0x30,
    ]);
    out.addAll(data);
    out.addAll(<int>[0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);
    return out;
  }

  static List<int> buildCode128(
    String content, {
    int height = 80,
    int width = 2,
  }) {
    final encoded = utf8.encode('{B$content');
    final out = <int>[];
    out.addAll(<int>[0x1D, 0x68, height.clamp(1, 255)]);
    out.addAll(<int>[0x1D, 0x77, width.clamp(2, 6)]);
    out.addAll(<int>[0x1D, 0x48, 0x02]);
    out.addAll(<int>[0x1D, 0x6B, 0x49, encoded.length]);
    out.addAll(encoded);
    return out;
  }
}
