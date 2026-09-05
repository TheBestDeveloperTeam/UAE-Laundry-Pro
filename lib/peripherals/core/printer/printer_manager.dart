import 'dart:convert';
import 'dart:io';

import 'package:laundrypro_uae/peripherals/core/logging/app_logger.dart';
import 'package:laundrypro_uae/peripherals/core/storage/app_database.dart';
import 'package:laundrypro_uae/peripherals/core/printer/esc_pos_generator.dart';
import 'package:laundrypro_uae/peripherals/core/printer/network_printer_discovery.dart';
import 'package:laundrypro_uae/peripherals/core/printer/paper_size.dart';
import 'package:laundrypro_uae/peripherals/core/printer/paper_source.dart';
import 'package:laundrypro_uae/peripherals/core/printer/pos_receipt_builder.dart';
import 'package:laundrypro_uae/peripherals/core/printer/pos_receipt_model.dart';
import 'package:laundrypro_uae/peripherals/core/printer/print_queue_manager.dart';
import 'package:laundrypro_uae/peripherals/core/printer/printer_models.dart';
import 'package:laundrypro_uae/peripherals/core/printer/raw_spooler_printer.dart';
import 'package:laundrypro_uae/peripherals/core/printer/receipt_template_repository.dart';
import 'package:laundrypro_uae/peripherals/core/printer/silent_print_engine.dart';

class PrinterManager {
  PrinterManager({
    required AppLogger logger,
    required AppDatabase database,
  })  : _logger = logger,
        _silentPrintEngine = SilentPrintEngine(logger: logger),
        _queueManager = PrintQueueManager(database: database),
        _rawSpoolerPrinter = RawSpoolerPrinter(),
        _escPosGenerator = EscPosGenerator(),
        _networkDiscovery = NetworkPrinterDiscovery(logger: logger),
        _templates = ReceiptTemplateRepository(database: database),
        _database = database;

  final AppLogger _logger;
  final SilentPrintEngine _silentPrintEngine;
  final PrintQueueManager _queueManager;
  final RawSpoolerPrinter _rawSpoolerPrinter;
  final EscPosGenerator _escPosGenerator;
  final NetworkPrinterDiscovery _networkDiscovery;
  final ReceiptTemplateRepository _templates;
  final AppDatabase _database;

  EscPosGenerator get escPos => _escPosGenerator;
  ReceiptTemplateRepository get templates => _templates;
  NetworkPrinterDiscovery get networkDiscovery => _networkDiscovery;

  Future<List<PrinterDeviceModel>> discoverWindowsPrinters() async {
    final result = await Process.run(
      'powershell',
      const [
        '-NoProfile',
        '-Command',
        'Get-Printer | Select-Object Name,Default,DriverName,PortName | ConvertTo-Json -Depth 3',
      ],
    );

    if (result.exitCode != 0) {
      await _logger.error(
        'Printer discovery failed',
        scope: 'printer',
        payload: {'stderr': result.stderr.toString()},
      );
      return const [];
    }

    final raw = result.stdout.toString().trim();
    if (raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    final rows = decoded is List ? decoded : [decoded];
    return rows
        .whereType<Map>()
        .map((row) => PrinterDeviceModel.fromMap(row.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> getPrinterStatus(String printerName) async {
    if (printerName.trim().isEmpty) {
      return {'error': 'printer name is empty'};
    }
    final escaped = printerName.replaceAll("'", "''");
    final cmd =
        "Get-Printer -Name '$escaped' | Select-Object Name,@{n='Status';e={\$_.PrinterStatus.ToString()}},JobCount,PortName,DriverName | ConvertTo-Json -Depth 3";
    final result = await Process.run(
      'powershell',
      ['-NoProfile', '-Command', cmd],
    );
    if (result.exitCode != 0) {
      return {
        'name': printerName,
        'status': 'Unknown',
        'error': result.stderr.toString().trim(),
      };
    }
    final out = result.stdout.toString().trim();
    if (out.isEmpty) {
      return {'name': printerName, 'status': 'Unknown'};
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(out) as Map);
    } catch (_) {
      return {'name': printerName, 'status': 'Unknown', 'raw': out};
    }
  }

  Future<void> printToInstalledPrinter({
    required String printerName,
    required List<int> payload,
  }) async {
    await _rawSpoolerPrinter.printBytes(
      printerName: printerName,
      payload: payload,
    );
    await _logger.info(
      'Spooler raw print sent',
      scope: 'printer',
      payload: {'printer': printerName, 'bytes': payload.length},
    );
  }

  Future<void> enqueuePrint(PrintJobModel job) async {
    await _queueManager.enqueue(job);
  }

  Future<List<Map<String, Object?>>> queueSnapshot({int limit = 200}) async {
    return _database.db.query(
      'print_queue',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  Future<void> retryQueuedJob({required String id}) async {
    await _database.db.update(
      'print_queue',
      {'status': 'queued', 'retries': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteQueuedJob({required String id}) async {
    await _database.db.delete(
      'print_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> flushQueueToInstalledPrinter({
    required String printerName,
  }) async {
    final queued = await _database.db.query(
      'print_queue',
      where: 'status = ? AND printer_name = ?',
      whereArgs: ['queued', printerName],
      orderBy: 'created_at ASC',
      limit: 20,
    );
    for (final row in queued) {
      final id = row['id'].toString();
      final payload = base64Decode(row['payload_base64'].toString());
      try {
        await printToInstalledPrinter(
          printerName: printerName,
          payload: payload,
        );
        await _database.db.update(
          'print_queue',
          {'status': 'printed'},
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (_) {
        final retries = ((row['retries'] as int?) ?? 0) + 1;
        await _database.db.update(
          'print_queue',
          {'status': retries > 3 ? 'failed' : 'queued', 'retries': retries},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
  }

  Future<void> silentPrintViaTcp({
    required String host,
    required int port,
    required List<int> payload,
  }) async {
    await _silentPrintEngine.printTcp(
      host: host,
      port: port,
      payload: payload,
    );
  }

  List<int> buildEscPosTestTicket({
    required String title,
    PaperSize paper = PaperSize.thermal80mm,
  }) {
    return _escPosGenerator.testReceipt(title: title, paper: paper);
  }

  List<int> buildCustomReceipt({
    required List<String> lines,
    String title = 'RECEIPT',
    String? footer,
    PaperSize paper = PaperSize.thermal80mm,
    int copies = 1,
    int arabicCodePage = 32,
    int defaultCodePage = 0,
    bool reverseArabicRtl = true,
  }) {
    return _escPosGenerator.customReceipt(
      lines: lines,
      title: title,
      footer: footer,
      paper: paper,
      copies: copies,
      arabicCodePage: arabicCodePage,
      defaultCodePage: defaultCodePage,
      reverseArabicRtl: reverseArabicRtl,
    );
  }

  List<int> cashDrawerPulse() => _escPosGenerator.cashDrawerPulse();

  /// Reads the paper trays / input sources reported by the Windows printer
  /// driver. Returns an empty list when the printer has no enumerable
  /// sources (e.g. most ESC/POS thermal printers).
  Future<List<PaperSourceModel>> discoverPaperSources(
    String printerName,
  ) async {
    if (printerName.trim().isEmpty) return const [];
    final escaped = printerName.replaceAll("'", "''");
    final cmd = "Add-Type -AssemblyName System.Drawing | Out-Null; "
        "\$ps = New-Object System.Drawing.Printing.PrinterSettings; "
        "\$ps.PrinterName = '$escaped'; "
        "\$ps.PaperSources | Select-Object @{n='Kind';e={\$_.Kind.ToString()}}, "
        "@{n='RawKind';e={\$_.RawKind}}, SourceName | ConvertTo-Json -Depth 3";
    final result = await Process.run(
      'powershell',
      ['-NoProfile', '-Command', cmd],
    );
    if (result.exitCode != 0) {
      await _logger.warning(
        'Paper source discovery failed',
        scope: 'printer',
        payload: {
          'printer': printerName,
          'stderr': result.stderr.toString(),
        },
      );
      return const [];
    }
    final raw = result.stdout.toString().trim();
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      final rows = decoded is List ? decoded : [decoded];
      return rows
          .whereType<Map>()
          .map((row) =>
              PaperSourceModel.fromMap(row.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  // ---- ESC/POS quick command builders -------------------------------------

  List<int> buildBeep({int times = 1, int duration = 5}) {
    return _escPosGenerator.beep(times: times, duration: duration);
  }

  List<int> buildFeed(int lines) => _escPosGenerator.feedLines(lines);

  List<int> buildFeedAndCut({int feed = 3}) =>
      _escPosGenerator.feedAndCut(feed: feed);

  List<int> buildRepeatedCut({int times = 3, int feed = 3}) =>
      _escPosGenerator.repeatedCut(times: times, feed: feed);

  /// General POS shop receipt (restaurant / garment) with bilingual EN+AR
  /// stacked lines, particulars table, VAT, discount, EAN-13, QR.
  List<int> buildPosShopReceipt({
    PosShopProfile? shop,
    List<PosReceiptLineItem>? items,
    PaperSize paper = PaperSize.thermal80mm,
    String? receiptNo,
    String? cashier,
    int arabicCodePage = 32,
    int defaultCodePage = 0,
    bool reverseArabicRtl = true,
    int copies = 1,
  }) {
    final builder = PosReceiptBuilder(
      shop: shop ?? const PosShopProfile(),
      items: items ?? const [],
      paper: paper,
      receiptNo: receiptNo,
      cashier: cashier,
    );
    return buildCustomReceipt(
      lines: builder.buildMarkupLines(),
      title: builder.shop.shopNameEn,
      paper: paper,
      copies: copies,
      arabicCodePage: arabicCodePage,
      defaultCodePage: defaultCodePage,
      reverseArabicRtl: reverseArabicRtl,
    );
  }

  List<ReceiptPreviewLine> buildPosShopPreview({
    PosShopProfile? shop,
    List<PosReceiptLineItem>? items,
    PaperSize paper = PaperSize.thermal80mm,
    String? receiptNo,
    String? cashier,
  }) {
    final builder = PosReceiptBuilder(
      shop: shop ?? const PosShopProfile(),
      items: items ?? const [],
      paper: paper,
      receiptNo: receiptNo,
      cashier: cashier,
    );
    return builder.buildPreviewLines();
  }
}

