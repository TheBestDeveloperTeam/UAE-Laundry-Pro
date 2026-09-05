import 'dart:convert';

import 'package:laundrypro_uae/peripherals/core/printer/paper_size.dart';
import 'package:laundrypro_uae/peripherals/core/printer/rich_line_formatter.dart';

class EscPosGenerator {
  static const List<int> _init = <int>[0x1B, 0x40];
  static const List<int> _alignCenter = <int>[0x1B, 0x61, 0x01];
  static const List<int> _alignLeft = <int>[0x1B, 0x61, 0x00];
  static const List<int> _partialCut = <int>[0x1D, 0x56, 0x41, 0x10];
  static const List<int> _drawerPulse = <int>[0x1B, 0x70, 0x00, 0x19, 0xFA];

  /// Default system test receipt — printed when no custom lines are given.
  List<int> testReceipt({
    required String title,
    PaperSize paper = PaperSize.thermal80mm,
  }) {
    final bytes = <int>[];
    bytes.addAll(_init);
    bytes.addAll(_alignCenter);
    bytes.addAll(utf8.encode('$title\n'));
    bytes.addAll(_alignLeft);
    bytes.addAll(utf8.encode('Peripheral Framework Test Ticket\n'));
    bytes.addAll(
      utf8.encode('Timestamp: ${DateTime.now().toIso8601String()}\n'),
    );
    bytes.addAll(utf8.encode('${'-' * paper.columns}\n'));
    bytes.addAll(utf8.encode('Paper: ${paper.label} (${paper.columns} cols)\n'));
    bytes.addAll(utf8.encode('Status: SUCCESS\n\n\n'));
    bytes.addAll(_partialCut);
    return bytes;
  }

  /// Builds an ESC/POS payload from user-entered lines.
  /// Lines support inline markup via [RichLineFormatter] including Arabic
  /// runs (auto code-page switch + RTL byte reversal).
  /// If [lines] is empty, returns the default system test receipt.
  List<int> customReceipt({
    required List<String> lines,
    String title = 'RECEIPT',
    String? footer,
    PaperSize paper = PaperSize.thermal80mm,
    int copies = 1,
    int arabicCodePage = 32,
    int defaultCodePage = 0,
    bool reverseArabicRtl = true,
  }) {
    final sanitized = lines
        .map((line) => line)
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);

    final ticket = <int>[];
    if (sanitized.isEmpty) {
      ticket.addAll(testReceipt(title: title, paper: paper));
    } else {
      final formatter = RichLineFormatter(
        paper: paper,
        arabicCodePage: arabicCodePage,
        defaultCodePage: defaultCodePage,
        reverseArabicRtl: reverseArabicRtl,
      );
      ticket.addAll(_init);
      ticket.addAll(formatter.formatLine('[C]$title[/C]'));
      ticket.addAll(formatter.formatLine('[HR]'));
      for (final line in sanitized) {
        ticket.addAll(formatter.formatLine(line));
      }
      ticket.addAll(formatter.formatLine('[HR]'));
      final footerText =
          footer ?? 'Printed at ${DateTime.now().toIso8601String()}';
      ticket.addAll(formatter.formatLine('[C]$footerText[/C]'));
      ticket.addAll(const <int>[0x0A, 0x0A, 0x0A]);
      ticket.addAll(_partialCut);
    }

    final normalizedCopies = copies.clamp(1, 20);
    if (normalizedCopies == 1) return ticket;

    final buffer = <int>[];
    for (var i = 0; i < normalizedCopies; i++) {
      buffer.addAll(ticket);
    }
    return buffer;
  }

  List<int> cashDrawerPulse() => List<int>.from(_drawerPulse);

  /// ESC B n t — n beeps of t·100 ms each. Both n and t clamped to 1..9.
  /// Note: not all ESC/POS printers honor this command; harmless if ignored.
  List<int> beep({int times = 1, int duration = 5}) {
    return <int>[
      0x1B,
      0x42,
      times.clamp(1, 9),
      duration.clamp(1, 9),
    ];
  }

  /// ESC d n — feed n lines (0..255).
  List<int> feedLines(int lines) {
    return <int>[0x1B, 0x64, lines.clamp(0, 255)];
  }

  /// Feed 3 lines and partial cut.
  List<int> feedAndCut({int feed = 3}) {
    final out = <int>[];
    out.addAll(feedLines(feed));
    out.addAll(_partialCut);
    return out;
  }

  /// Repeats feed+cut `times` times. Useful for testing thermal printer
  /// cutter mechanics or producing multiple separated stubs.
  List<int> repeatedCut({int times = 3, int feed = 3}) {
    final out = <int>[];
    for (var i = 0; i < times.clamp(1, 20); i++) {
      out.addAll(feedAndCut(feed: feed));
    }
    return out;
  }
}

