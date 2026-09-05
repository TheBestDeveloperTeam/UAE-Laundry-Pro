import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:laundrypro_uae/peripherals/core/printer/paper_size.dart';
import 'package:laundrypro_uae/peripherals/core/printer/pos_receipt_builder.dart';
import 'package:laundrypro_uae/peripherals/core/printer/pos_receipt_model.dart';
import 'package:laundrypro_uae/peripherals/core/printer/printer_models.dart';
import 'package:laundrypro_uae/peripherals/core/printer/receipt_template.dart';
import 'package:laundrypro_uae/peripherals/features/shared/providers/app_providers.dart';
import 'package:laundrypro_uae/peripherals/features/printer/widgets/hex_preview_dialog.dart';
import 'package:laundrypro_uae/peripherals/features/printer/widgets/network_scan_dialog.dart';
import 'package:laundrypro_uae/peripherals/features/printer/widgets/print_preview_dialog.dart';
import 'package:laundrypro_uae/peripherals/features/printer/widgets/printer_status_badge.dart';
import 'package:laundrypro_uae/peripherals/features/printer/widgets/template_picker_dialog.dart';

class PrinterPanel extends ConsumerStatefulWidget {
  const PrinterPanel({super.key});

  @override
  ConsumerState<PrinterPanel> createState() => _PrinterPanelState();
}

class _PrinterPanelState extends ConsumerState<PrinterPanel> {
  final List<TextEditingController> _lineControllers = [];
  final FocusNode _shortcutsFocus = FocusNode(debugLabel: 'printer-shortcuts');
  bool _autoSelectedDefaultPrinter = false;
  String? _statusMessage;

  @override
  void dispose() {
    for (final c in _lineControllers) {
      c.dispose();
    }
    _shortcutsFocus.dispose();
    super.dispose();
  }

  List<String> _collectLines() => _lineControllers
      .map((c) => c.text)
      .where((line) => line.trim().isNotEmpty)
      .toList(growable: false);

  void _addLine([String initial = '']) {
    setState(() {
      _lineControllers.add(TextEditingController(text: initial));
    });
  }

  void _removeLine(int index) {
    setState(() {
      final controller = _lineControllers.removeAt(index);
      controller.dispose();
    });
  }

  void _replaceLines(List<String> lines) {
    setState(() {
      for (final c in _lineControllers) {
        c.dispose();
      }
      _lineControllers
        ..clear()
        ..addAll(lines.map((line) => TextEditingController(text: line)));
    });
  }

  void _clearLines() => _replaceLines(const []);

  Future<void> _saveAsTemplate() async {
    final lines = _collectLines();
    if (lines.isEmpty) {
      _toast('No custom lines to save.');
      return;
    }
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Save Template'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Template name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final paper = ref.read(paperSizeProvider);
    final manager = ref.read(printerManagerProvider);
    await manager.templates.save(
      ReceiptTemplate(
        id: '',
        name: name,
        lines: lines,
        paper: paper,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    ref.invalidate(receiptTemplatesProvider);
    _toast('Template "$name" saved.');
  }

  Future<void> _loadTemplate() async {
    final picked = await TemplatePickerDialog.show(context);
    if (picked == null) return;
    ref.read(paperSizeProvider.notifier).state = picked.paper;
    _replaceLines(picked.lines);
    _toast('Loaded template "${picked.name}".');
  }

  Future<void> _showHexPreview() async {
    final payload = _buildPayload();
    await HexPreviewDialog.show(
      context,
      payload: payload,
      title: 'ESC/POS Hex Preview',
    );
  }

  List<int> _buildPayload() {
    final manager = ref.read(printerManagerProvider);
    final lines = _collectLines();
    final paper = ref.read(paperSizeProvider);
    final copies = ref.read(printCopiesProvider);
    final title = ref.read(receiptTitleProvider);
    final arabicCodePage = ref.read(arabicCodePageProvider);
    final reverseArabicRtl = ref.read(reverseArabicRtlProvider);

    if (lines.isEmpty) {
      return manager.buildPosShopReceipt(
        paper: paper,
        copies: copies,
        arabicCodePage: arabicCodePage,
        reverseArabicRtl: reverseArabicRtl,
      );
    }

    return manager.buildCustomReceipt(
      lines: lines,
      title: title.isEmpty ? 'RECEIPT' : title,
      paper: paper,
      copies: copies,
      arabicCodePage: arabicCodePage,
      reverseArabicRtl: reverseArabicRtl,
    );
  }

  List<ReceiptPreviewLine> _buildPreviewLines() {
    final custom = _collectLines();
    if (custom.isNotEmpty) {
      return custom.map(_previewLineFromMarkup).toList();
    }
    return PosReceiptBuilder.sample(paper: ref.read(paperSizeProvider))
        .buildPreviewLines();
  }

  ReceiptPreviewLine _previewLineFromMarkup(String raw) {
    final line = raw.trim();
    if (line.toUpperCase() == '[HR]') {
      return const ReceiptPreviewLine(text: '', isRule: true);
    }
    final lr = RegExp(
      r'^\[LR\](.+?)\|(.+?)\[/LR\]$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(line);
    if (lr != null) {
      return ReceiptPreviewLine(
        text: lr.group(1)!.trim(),
        rightText: lr.group(2)!.trim(),
        align: ReceiptTextAlign.left,
      );
    }
    final biLeft = RegExp(
      r'^\[L\]\s*\[BI\](.+?)\|(.+?)\[/BI\]',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(line);
    if (biLeft != null) {
      return ReceiptPreviewLine(
        text: biLeft.group(1)!.trim(),
        textAr: biLeft.group(2)!.trim(),
        align: ReceiptTextAlign.left,
      );
    }
    final bi = RegExp(
      r'^\[BI\](.+?)\|(.+?)\[/BI\]$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(line);
    if (bi != null) {
      return ReceiptPreviewLine(
        text: bi.group(1)!.trim(),
        textAr: bi.group(2)!.trim(),
        align: ReceiptTextAlign.center,
      );
    }
    final bc = RegExp(r'^\[BC\](.+?)\[/BC\]$', caseSensitive: false)
        .firstMatch(line);
    if (bc != null) {
      return ReceiptPreviewLine(
        text: 'Code128',
        align: ReceiptTextAlign.center,
        isCode128: true,
        barcodeLabel: bc.group(1)!.trim(),
      );
    }
    final qr = RegExp(r'^\[QR\](.+?)\[/QR\]$', caseSensitive: false)
        .firstMatch(line);
    if (qr != null) {
      return ReceiptPreviewLine(
        text: 'QR Code',
        align: ReceiptTextAlign.center,
        isQr: true,
        barcodeLabel: qr.group(1)!.trim(),
      );
    }
    final ean = RegExp(r'^\[EAN13\](\d+)\[/EAN13\]$', caseSensitive: false)
        .firstMatch(line);
    if (ean != null) {
      return ReceiptPreviewLine(
        text: 'EAN-13',
        align: ReceiptTextAlign.center,
        isBarcode: true,
        barcodeLabel: ean.group(1)!.trim(),
      );
    }
    var text = line;
    var center = false;
    var bold = false;
    var big = false;
    var right = false;
    if (RegExp(r'^\[R\]', caseSensitive: false).hasMatch(text)) {
      right = true;
      text = text.replaceAll(RegExp(r'^\[R\]|\[/R\]$', caseSensitive: false), '');
    }
    if (RegExp(r'^\[C\]', caseSensitive: false).hasMatch(text)) {
      center = true;
      text = text.replaceAll(RegExp(r'^\[C\]|\[/C\]$', caseSensitive: false), '');
    }
    if (RegExp(r'^\[L\]', caseSensitive: false).hasMatch(text)) {
      text = text.replaceAll(RegExp(r'^\[L\]|\[/L\]$', caseSensitive: false), '');
    }
    if (RegExp(r'\[B\]', caseSensitive: false).hasMatch(text)) {
      bold = true;
      text = text.replaceAll(RegExp(r'\[B\]|\[/B\]', caseSensitive: false), '');
    }
    if (RegExp(r'\[BIG\]', caseSensitive: false).hasMatch(text)) {
      big = true;
      text = text.replaceAll(RegExp(r'\[BIG\]|\[/BIG\]', caseSensitive: false), '');
    }
    return ReceiptPreviewLine(
      text: text.trim(),
      align: center
          ? ReceiptTextAlign.center
          : right
              ? ReceiptTextAlign.right
              : ReceiptTextAlign.left,
      bold: bold,
      big: big,
    );
  }

  Future<void> _print() async {
    await _sendBytes(_buildPayload(), label: 'Receipt');
  }

  Future<void> _previewAndPrint() async {
    await PrintPreviewDialog.show(
      context,
      previewLines: _buildPreviewLines(),
      title: 'Print Preview — Receipt',
      onBuildPayload: _buildPayload,
      onPrint: () => _sendBytes(_buildPayload(), label: 'Receipt'),
    );
  }

  Future<void> _previewPosSample() async {
    final manager = ref.read(printerManagerProvider);
    final paper = ref.read(paperSizeProvider);
    final sample = PosReceiptBuilder.sample(paper: paper);
    final preview = sample.buildPreviewLines();
    await PrintPreviewDialog.show(
      context,
      previewLines: preview,
      title: 'POS Shop Receipt Preview',
      onBuildPayload: () => manager.buildPosShopReceipt(
        paper: paper,
        copies: ref.read(printCopiesProvider),
        arabicCodePage: ref.read(arabicCodePageProvider),
        reverseArabicRtl: ref.read(reverseArabicRtlProvider),
      ),
      onPrint: () => _sendBytes(
        manager.buildPosShopReceipt(
          paper: paper,
          copies: ref.read(printCopiesProvider),
          arabicCodePage: ref.read(arabicCodePageProvider),
          reverseArabicRtl: ref.read(reverseArabicRtlProvider),
        ),
        label: 'POS Receipt',
      ),
    );
  }

  void _loadPosSampleLines() {
    final sample = PosReceiptBuilder.sample(paper: ref.read(paperSizeProvider));
    _replaceLines(sample.buildMarkupLines());
    ref.read(receiptTitleProvider.notifier).state = sample.shop.shopNameEn;
    _toast('Loaded POS shop receipt template.');
  }

  /// Sends arbitrary ESC/POS bytes through the currently selected
  /// connection (spooler or TCP). Used by both receipt prints and the
  /// quick command buttons (beep/feed/cut).
  Future<void> _sendBytes(List<int> payload, {required String label}) async {
    if (payload.isEmpty) {
      _toast('Nothing to send.');
      return;
    }
    final mode = ref.read(printerConnectionModeProvider);
    final manager = ref.read(printerManagerProvider);
    try {
      setState(() => _statusMessage = 'Sending $label...');
      if (mode == PrinterConnectionMode.spooler) {
        final printer = ref.read(selectedPrinterProvider);
        if (printer == null) {
          _toast('Select a printer first.');
          return;
        }
        await manager.printToInstalledPrinter(
          printerName: printer,
          payload: payload,
        );
        setState(() {
          _statusMessage =
              '$label sent · ${payload.length} bytes → Spooler "$printer".';
        });
      } else {
        final host = ref.read(printerHostProvider);
        final port = ref.read(printerPortProvider);
        await manager.silentPrintViaTcp(
          host: host,
          port: port,
          payload: payload,
        );
        setState(() {
          _statusMessage =
              '$label sent · ${payload.length} bytes → TCP $host:$port.';
        });
      }
    } catch (error) {
      setState(() => _statusMessage = '$label failed: $error');
    }
  }

  Future<void> _enqueue() async {
    final payload = _buildPayload();
    final mode = ref.read(printerConnectionModeProvider);
    final printerName = mode == PrinterConnectionMode.spooler
        ? (ref.read(selectedPrinterProvider) ?? '')
        : '${ref.read(printerHostProvider)}:${ref.read(printerPortProvider)}';
    if (printerName.isEmpty) {
      _toast('Select a printer first.');
      return;
    }
    await ref.read(printerManagerProvider).enqueuePrint(
          PrintJobModel(
            printerName: printerName,
            connectionType: mode.name,
            payload: payload,
          ),
        );
    _toast('Queued for $printerName');
  }

  Future<void> _flushQueue() async {
    final printer = ref.read(selectedPrinterProvider);
    if (printer == null) {
      _toast('Select a printer first.');
      return;
    }
    await ref
        .read(printerManagerProvider)
        .flushQueueToInstalledPrinter(printerName: printer);
    _toast('Flushed queue for $printer');
  }

  Future<void> _openNetworkScan() async {
    final candidate = await NetworkScanDialog.show(context);
    if (candidate == null) return;
    ref.read(printerHostProvider.notifier).state = candidate.host;
    ref.read(printerPortProvider.notifier).state = candidate.port;
    ref.read(printerConnectionModeProvider.notifier).state =
        PrinterConnectionMode.tcp;
    _toast('Selected ${candidate.host}:${candidate.port} (TCP)');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<PrinterDeviceModel>>>(printersProvider,
        (_, next) {
      next.whenData((items) {
        if (_autoSelectedDefaultPrinter || items.isEmpty) return;
        final current = ref.read(selectedPrinterProvider);
        if (current != null) {
          _autoSelectedDefaultPrinter = true;
          return;
        }
        final defaultPrinter = items.firstWhere(
          (p) => p.isDefault,
          orElse: () => items.first,
        );
        ref.read(selectedPrinterProvider.notifier).state = defaultPrinter.name;
        _autoSelectedDefaultPrinter = true;
      });
    });

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): _print,
        const SingleActivator(LogicalKeyboardKey.keyL, control: true):
            _addLine,
      },
      child: Focus(
        focusNode: _shortcutsFocus,
        autofocus: true,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _header(),
            _connectionSection(),
            const SizedBox(height: 12),
            _formatSection(),
            const SizedBox(height: 12),
            _arabicSection(),
            const SizedBox(height: 12),
            _posReceiptSection(),
            const SizedBox(height: 12),
            const Divider(),
            _linesSection(),
            const SizedBox(height: 16),
            _actionsSection(),
            const SizedBox(height: 12),
            _quickCommandsSection(),
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _statusMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Printer Engine',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Tooltip(
          message: 'Ctrl+P prints · Ctrl+L adds a line',
          child: IconButton(
            icon: const Icon(Icons.keyboard),
            onPressed: () => _toast('Shortcuts: Ctrl+P print · Ctrl+L add line'),
          ),
        ),
        IconButton(
          tooltip: 'Refresh printers',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(printersProvider),
        ),
      ],
    );
  }

  Widget _connectionSection() {
    final mode = ref.watch(printerConnectionModeProvider);
    final printers = ref.watch(printersProvider);
    final selectedPrinter = ref.watch(selectedPrinterProvider);
    final host = ref.watch(printerHostProvider);
    final port = ref.watch(printerPortProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<PrinterConnectionMode>(
              segments: const [
                ButtonSegment(
                  value: PrinterConnectionMode.spooler,
                  label: Text('Windows Spooler'),
                  icon: Icon(Icons.devices_other),
                ),
                ButtonSegment(
                  value: PrinterConnectionMode.tcp,
                  label: Text('Network TCP'),
                  icon: Icon(Icons.lan),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (set) {
                ref.read(printerConnectionModeProvider.notifier).state =
                    set.first;
              },
            ),
            const SizedBox(height: 12),
            if (mode == PrinterConnectionMode.spooler) ...[
              printers.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No installed printers found.'),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: selectedPrinter,
                    items: items
                        .map((p) => DropdownMenuItem<String>(
                              value: p.name,
                              child: Text(
                                p.isDefault ? '${p.name}  (default)' : p.name,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) => ref
                        .read(selectedPrinterProvider.notifier)
                        .state = value,
                    decoration: const InputDecoration(
                      labelText: 'Windows Printer',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Discovery failed: $e'),
              ),
              if (selectedPrinter != null) ...[
                const SizedBox(height: 8),
                PrinterStatusBadge(name: selectedPrinter),
              ],
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('host-$host'),
                      initialValue: host,
                      decoration: const InputDecoration(
                        labelText: 'TCP Host',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) =>
                          ref.read(printerHostProvider.notifier).state = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: TextFormField(
                      key: ValueKey('port-$port'),
                      initialValue: '$port',
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
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Discover network printers',
                    icon: const Icon(Icons.travel_explore),
                    onPressed: _openNetworkScan,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _formatSection() {
    final paper = ref.watch(paperSizeProvider);
    final copies = ref.watch(printCopiesProvider);
    final title = ref.watch(receiptTitleProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<PaperSize>(
                    initialValue: paper,
                    items: PaperSize.values
                        .map((p) => DropdownMenuItem<PaperSize>(
                              value: p,
                              child: Text('${p.label} (${p.columns} cols)'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(paperSizeProvider.notifier).state = value;
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Paper Size',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    initialValue: '$copies',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Copies',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final next = int.tryParse(v) ?? 1;
                      ref.read(printCopiesProvider.notifier).state =
                          next.clamp(1, 20);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: title,
              decoration: const InputDecoration(
                labelText: 'Receipt Title',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) =>
                  ref.read(receiptTitleProvider.notifier).state = v,
            ),
            const SizedBox(height: 12),
            _paperSourceDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _paperSourceDropdown() {
    final sourcesAsync = ref.watch(paperSourcesProvider);
    final selected = ref.watch(selectedPaperSourceProvider);

    return sourcesAsync.when(
      data: (sources) {
        if (sources.isEmpty) {
          return const InputDecorator(
            decoration: InputDecoration(
              labelText: 'Paper Tray',
              border: OutlineInputBorder(),
              helperText:
                  'No selectable trays reported by this printer driver.',
            ),
            child: Text('Default / single source'),
          );
        }
        final items = [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Driver default'),
          ),
          ...sources.map(
            (s) => DropdownMenuItem<String?>(
              value: s.sourceName.isEmpty ? s.kind : s.sourceName,
              child: Text(s.displayLabel),
            ),
          ),
        ];
        final exists = selected == null ||
            sources.any(
              (s) =>
                  (s.sourceName.isEmpty ? s.kind : s.sourceName) == selected,
            );
        return DropdownButtonFormField<String?>(
          initialValue: exists ? selected : null,
          items: items,
          onChanged: (value) =>
              ref.read(selectedPaperSourceProvider.notifier).state = value,
          decoration: const InputDecoration(
            labelText: 'Paper Tray',
            border: OutlineInputBorder(),
            helperText:
                'Advisory: applied only when the printer uses a driver path '
                '(GDI). RAW ESC/POS prints ignore tray selection.',
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => InputDecorator(
        decoration: InputDecoration(
          labelText: 'Paper Tray',
          border: const OutlineInputBorder(),
          helperText: 'Tray lookup failed: $e',
        ),
        child: const Text('Default / single source'),
      ),
    );
  }

  Widget _arabicSection() {
    final codePage = ref.watch(arabicCodePageProvider);
    final reverseRtl = ref.watch(reverseArabicRtlProvider);
    const knownCodePages = <int, String>{
      22: '22 — PC864 (Arabic)',
      30: '30 — TCVN-3 / Vietnamese',
      32: '32 — WPC1256 (recommended)',
      37: '37 — WPC1252',
      39: '39 — ISO 8859-6 (Arabic)',
      41: '41 — Code Page 41',
    };
    final entries = knownCodePages.entries.toList();
    if (!knownCodePages.containsKey(codePage)) {
      entries.insert(
        0,
        MapEntry(codePage, '$codePage — Custom'),
      );
    }

    return Card(
      child: ExpansionTile(
        title: const Row(
          children: [
            Icon(Icons.translate, size: 18),
            SizedBox(width: 6),
            Text(
              'Arabic / RTL Settings',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        subtitle: Text(
          'Code page $codePage · ${reverseRtl ? 'RTL reverse ON' : 'RTL reverse OFF'}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'When a line contains Arabic characters the printer is '
              'temporarily switched to the selected code page via ESC t n, '
              'Arabic runs are reversed (so they read right-to-left on '
              'paper), then bytes are encoded as CP1256.',
              style: TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: codePage,
                  items: entries
                      .map(
                        (e) => DropdownMenuItem<int>(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(arabicCodePageProvider.notifier).state = value;
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Arabic Code Page (ESC t n)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: TextFormField(
                  key: ValueKey('cp-$codePage'),
                  initialValue: '$codePage',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Custom n',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    final next = int.tryParse(v);
                    if (next != null && next >= 0 && next <= 255) {
                      ref.read(arabicCodePageProvider.notifier).state = next;
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: reverseRtl,
            onChanged: (v) =>
                ref.read(reverseArabicRtlProvider.notifier).state = v,
            title: const Text('Reverse Arabic runs for RTL output'),
            subtitle: const Text(
              'Keep ON for most printers. Turn OFF only if Arabic text '
              'prints mirrored on your hardware.',
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.science),
              label: const Text('Insert Arabic sample lines'),
              onPressed: () {
                _replaceLines(<String>[
                  '[C][B]فاتورة[/B][/C]',
                  '[C]مرحبا بكم[/C]',
                  'المنتج: قهوة عربية',
                  'الكمية: 2',
                  'السعر: 25 ريال',
                  '[HR]',
                  '[R]شكرا[/R]',
                ]);
                _toast('Inserted Arabic sample lines.');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _posReceiptSection() {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer.withValues(
            alpha: 0.25,
          ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'POS Shop Receipt (EN + AR)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'General template for restaurant / garment: jumbo shop name, '
              'bilingual address (English with Arabic directly below), striped '
              'particulars table, VAT 5%, discount 2%, EAN-13 + QR, thank you.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Preview POS Receipt'),
                  onPressed: _previewPosSample,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Load into Editor'),
                  onPressed: _loadPosSampleLines,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickCommandsSection() {
    final mode = ref.watch(printerConnectionModeProvider);
    final selectedPrinter = ref.watch(selectedPrinterProvider);
    final canSend = mode == PrinterConnectionMode.tcp ||
        (mode == PrinterConnectionMode.spooler && selectedPrinter != null);
    final manager = ref.read(printerManagerProvider);

    Future<void> send(String label, List<int> Function() builder) async {
      await _sendBytes(builder(), label: label);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt, size: 18),
                SizedBox(width: 6),
                Text(
                  'Quick Commands',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Beep ×1'),
                  onPressed:
                      canSend ? () => send('Beep ×1', () => manager.buildBeep(times: 1)) : null,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Beep ×3'),
                  onPressed: canSend
                      ? () =>
                          send('Beep ×3', () => manager.buildBeep(times: 3))
                      : null,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text('Feed 3 lines'),
                  onPressed:
                      canSend ? () => send('Feed 3', () => manager.buildFeed(3)) : null,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.keyboard_double_arrow_down),
                  label: const Text('Feed 9 lines'),
                  onPressed:
                      canSend ? () => send('Feed 9', () => manager.buildFeed(9)) : null,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.content_cut),
                  label: const Text('Cut ×1'),
                  onPressed: canSend
                      ? () => send(
                            'Cut ×1',
                            () => manager.buildFeedAndCut(feed: 3),
                          )
                      : null,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.cut),
                  label: const Text('Cut ×3'),
                  onPressed: canSend
                      ? () => send(
                            'Cut ×3',
                            () => manager
                                .buildRepeatedCut(times: 3, feed: 3),
                          )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _linesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Custom Receipt Lines',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.bookmark),
              label: const Text('Load'),
              onPressed: _loadTemplate,
            ),
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: _saveAsTemplate,
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Line'),
              onPressed: () => _addLine(),
            ),
            if (_lineControllers.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear'),
                onPressed: _clearLines,
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Markup supported per line:\n'
              '  [C]centered[/C]  [R]right[/R]  [B]bold[/B]  [BIG]double size[/BIG]\n'
              '  [QR]url[/QR]  [BC]code128[/BC]  [LR]label|price[/LR]  [R3]item|qty|total[/R3]  [HR]\n'
              'Empty list prints the default system test receipt.',
              style: TextStyle(fontFamily: 'monospace', height: 1.35),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ..._lineControllers.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          isDense: true,
                          border: const OutlineInputBorder(),
                          labelText: 'Line ${entry.key + 1}',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove line',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _removeLine(entry.key),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _actionsSection() {
    final mode = ref.watch(printerConnectionModeProvider);
    final selectedPrinter = ref.watch(selectedPrinterProvider);
    final canPrint = mode == PrinterConnectionMode.tcp ||
        (mode == PrinterConnectionMode.spooler && selectedPrinter != null);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.flash_on),
          label: const Text('Silent Print (Ctrl+P)'),
          onPressed: canPrint ? _print : null,
        ),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.preview),
          label: const Text('Preview & Print'),
          onPressed: canPrint ? _previewAndPrint : null,
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.code),
          label: const Text('Preview Hex'),
          onPressed: _showHexPreview,
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.playlist_add),
          label: const Text('Queue Job'),
          onPressed: canPrint ? _enqueue : null,
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.cloud_upload_outlined),
          label: const Text('Flush Queue'),
          onPressed: mode == PrinterConnectionMode.spooler &&
                  selectedPrinter != null
              ? _flushQueue
              : null,
        ),
      ],
    );
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
