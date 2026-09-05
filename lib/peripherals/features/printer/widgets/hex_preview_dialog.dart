import 'package:flutter/material.dart';

class HexPreviewDialog extends StatelessWidget {
  const HexPreviewDialog({
    super.key,
    required this.payload,
    required this.title,
    this.onPrint,
    this.printLabel = 'Print',
  });

  final List<int> payload;
  final String title;

  /// Optional callback. When provided, the dialog shows a primary "Print"
  /// button that invokes it (so the dialog acts as a preview-and-print step).
  final Future<void> Function()? onPrint;
  final String printLabel;

  static Future<void> show(
    BuildContext context, {
    required List<int> payload,
    String title = 'ESC/POS Payload',
    Future<void> Function()? onPrint,
    String printLabel = 'Print',
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => HexPreviewDialog(
        payload: payload,
        title: title,
        onPrint: onPrint,
        printLabel: printLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 540),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text('${payload.length} bytes'),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    _formatHexDump(payload),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
              if (onPrint != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.print),
                      label: Text(printLabel),
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await onPrint!.call();
                        if (navigator.mounted) navigator.pop();
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatHexDump(List<int> bytes) {
    final buf = StringBuffer();
    for (var i = 0; i < bytes.length; i += 16) {
      final chunk = bytes.skip(i).take(16).toList();
      buf.write(i.toRadixString(16).padLeft(8, '0'));
      buf.write('  ');
      for (var j = 0; j < 16; j++) {
        if (j < chunk.length) {
          buf.write(chunk[j].toRadixString(16).padLeft(2, '0'));
          buf.write(' ');
        } else {
          buf.write('   ');
        }
        if (j == 7) buf.write(' ');
      }
      buf.write(' ');
      for (final b in chunk) {
        buf.write((b >= 32 && b < 127) ? String.fromCharCode(b) : '.');
      }
      buf.writeln();
    }
    return buf.toString();
  }
}
