import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:laundrypro_uae/peripherals/core/printer/paper_size.dart';
import 'package:laundrypro_uae/peripherals/core/printer/pos_receipt_model.dart';
import 'package:laundrypro_uae/peripherals/core/printer/printer_models.dart';
import 'package:laundrypro_uae/peripherals/features/shared/providers/app_providers.dart';
import 'package:laundrypro_uae/peripherals/features/printer/widgets/receipt_preview_widget.dart';

/// Visual print preview with page-setup style options (printer, paper, copies).
class PrintPreviewDialog extends ConsumerStatefulWidget {
  const PrintPreviewDialog({
    super.key,
    required this.previewLines,
    required this.title,
    required this.onBuildPayload,
    required this.onPrint,
  });

  final List<ReceiptPreviewLine> previewLines;
  final String title;
  final List<int> Function() onBuildPayload;
  final Future<void> Function() onPrint;

  static Future<void> show(
    BuildContext context, {
    required List<ReceiptPreviewLine> previewLines,
    String title = 'Print Preview',
    required List<int> Function() onBuildPayload,
    required Future<void> Function() onPrint,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PrintPreviewDialog(
        previewLines: previewLines,
        title: title,
        onBuildPayload: onBuildPayload,
        onPrint: onPrint,
      ),
    );
  }

  @override
  ConsumerState<PrintPreviewDialog> createState() => _PrintPreviewDialogState();
}

class _PrintPreviewDialogState extends ConsumerState<PrintPreviewDialog> {
  bool _printing = false;

  @override
  Widget build(BuildContext context) {
    final paper = ref.watch(paperSizeProvider);
    final copies = ref.watch(printCopiesProvider);
    final mode = ref.watch(printerConnectionModeProvider);
    final printers = ref.watch(printersProvider);
    final selectedPrinter = ref.watch(selectedPrinterProvider);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.print_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _printing ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Preview shows how the receipt will look on thermal paper. '
                'Adjust printer and paper settings below, then print silently.',
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Card(
                        color: Colors.grey.shade900.withValues(alpha: 0.04),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: ReceiptPreviewWidget(
                              lines: widget.previewLines,
                              paper: paper,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _PageSetupPanel(
                        mode: mode,
                        printers: printers,
                        selectedPrinter: selectedPrinter,
                        paper: paper,
                        copies: copies,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _printing ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.settings),
                    label: const Text('Page Setup'),
                    onPressed: _printing
                        ? null
                        : () => _showPageSetupSheet(context),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: _printing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print),
                    label: const Text('Print'),
                    onPressed: _printing ? null : _confirmPrint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmPrint() async {
    setState(() => _printing = true);
    try {
      await widget.onPrint();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  void _showPageSetupSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: _PageSetupPanel(
          mode: ref.read(printerConnectionModeProvider),
          printers: ref.read(printersProvider),
          selectedPrinter: ref.read(selectedPrinterProvider),
          paper: ref.read(paperSizeProvider),
          copies: ref.read(printCopiesProvider),
          expanded: true,
        ),
      ),
    );
  }
}

class _PageSetupPanel extends ConsumerWidget {
  const _PageSetupPanel({
    required this.mode,
    required this.printers,
    required this.selectedPrinter,
    required this.paper,
    required this.copies,
    this.expanded = false,
  });

  final PrinterConnectionMode mode;
  final AsyncValue<List<PrinterDeviceModel>> printers;
  final String? selectedPrinter;
  final PaperSize paper;
  final int copies;
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Page Setup',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<PrinterConnectionMode>(
          segments: const [
            ButtonSegment(
              value: PrinterConnectionMode.spooler,
              label: Text('Windows Printer'),
              icon: Icon(Icons.devices_other, size: 18),
            ),
            ButtonSegment(
              value: PrinterConnectionMode.tcp,
              label: Text('Network TCP'),
              icon: Icon(Icons.lan, size: 18),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (set) {
            ref.read(printerConnectionModeProvider.notifier).state = set.first;
          },
        ),
        const SizedBox(height: 12),
        if (mode == PrinterConnectionMode.spooler)
          printers.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text('No printers found.');
              }
              return DropdownButtonFormField<String>(
                initialValue: selectedPrinter,
                decoration: const InputDecoration(
                  labelText: 'Printer',
                  border: OutlineInputBorder(),
                ),
                items: items
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p.name,
                        child: Text(p.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    ref.read(selectedPrinterProvider.notifier).state = v,
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Printer list error: $e'),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: ref.read(printerHostProvider),
                  decoration: const InputDecoration(
                    labelText: 'Host',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      ref.read(printerHostProvider.notifier).state = v,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: TextFormField(
                  initialValue: '${ref.read(printerPortProvider)}',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      ref.read(printerPortProvider.notifier).state =
                          int.tryParse(v) ?? 9100,
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        DropdownButtonFormField<PaperSize>(
          initialValue: paper,
          decoration: const InputDecoration(
            labelText: 'Paper / Roll Size',
            border: OutlineInputBorder(),
          ),
          items: PaperSize.values
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Text('${p.label} (${p.columns} cols)'),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) ref.read(paperSizeProvider.notifier).state = v;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: '$copies',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Copies',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) {
            final n = int.tryParse(v) ?? 1;
            ref.read(printCopiesProvider.notifier).state = n.clamp(1, 20);
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Silent print: no Windows dialog. RAW ESC/POS is sent directly.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );

    if (expanded) return content;
    return Card(child: Padding(padding: const EdgeInsets.all(12), child: content));
  }
}
