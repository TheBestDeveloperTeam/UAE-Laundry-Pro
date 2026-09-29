import 'package:flutter/material.dart';

import 'package:laundrypro_uae/peripherals/core/printer/paper_size.dart';
import 'package:laundrypro_uae/peripherals/core/printer/pos_receipt_model.dart';

/// Renders a thermal receipt as it would appear on paper (monospace layout).
class ReceiptPreviewWidget extends StatelessWidget {
  const ReceiptPreviewWidget({
    super.key,
    required this.lines,
    this.paper = PaperSize.thermal80mm,
    this.width,
  });

  final List<ReceiptPreviewLine> lines;
  final PaperSize paper;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final paperWidth = width ?? _paperPixelWidth(paper);
    final theme = Theme.of(context);

    return Container(
      width: paperWidth,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        border: Border.all(color: Colors.grey.shade400),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: lines.map((line) => _buildLine(line, theme)).toList(),
        ),
      ),
    );
  }

  double _paperPixelWidth(PaperSize paper) {
    return switch (paper) {
      PaperSize.thermal58mm => 280,
      PaperSize.thermal80mm => 380,
      PaperSize.a6 => 420,
      PaperSize.a5 => 480,
      PaperSize.a4 => 520,
    };
  }

  Widget _buildLine(ReceiptPreviewLine line, ThemeData theme) {
    if (line.isRule) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Divider(color: Colors.grey.shade600, height: 1),
      );
    }

    if (line.isBarcode) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black87),
              ),
              child: Text(
                '||||| ${line.barcodeLabel ?? ''} |||||',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'EAN-13',
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (line.isCode128) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black87),
              ),
              child: Text(
                line.barcodeLabel ?? '',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Code128',
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (line.isQr) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black87, width: 2),
              ),
              child: const Icon(Icons.qr_code_2, size: 72),
            ),
            const SizedBox(height: 4),
            Text(
              line.barcodeLabel ?? '',
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    final align = switch (line.align) {
      ReceiptTextAlign.center => TextAlign.center,
      ReceiptTextAlign.right => TextAlign.right,
      ReceiptTextAlign.left => TextAlign.left,
    };

    final baseStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: line.big ? 16 : 12,
      fontWeight: line.bold ? FontWeight.bold : FontWeight.normal,
      color: Colors.black87,
      height: 1.25,
    );

    if (line.rightText != null && line.rightText!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(line.text, style: baseStyle, textAlign: TextAlign.left),
                  if (line.textAr != null && line.textAr!.trim().isNotEmpty)
                    Text(
                      line.textAr!,
                      style: baseStyle.copyWith(fontSize: (line.big ? 14 : 11)),
                      textAlign: TextAlign.left,
                    ),
                ],
              ),
            ),
            Text(
              line.rightText!,
              style: baseStyle,
              textAlign: TextAlign.right,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(line.text, style: baseStyle, textAlign: align),
          if (line.textAr != null && line.textAr!.trim().isNotEmpty)
            Text(
              line.textAr!,
              style: baseStyle.copyWith(fontSize: (line.big ? 14 : 11)),
              textAlign: align,
            ),
        ],
      ),
    );
  }
}
