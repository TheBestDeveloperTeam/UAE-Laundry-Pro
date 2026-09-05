import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:laundrypro_uae/peripherals/core/logging/app_logger.dart';
import 'package:laundrypro_uae/peripherals/core/machine_info/machine_identity_manager.dart';
import 'package:laundrypro_uae/peripherals/core/printer/network_printer_discovery.dart';
import 'package:laundrypro_uae/peripherals/core/printer/paper_size.dart';
import 'package:laundrypro_uae/peripherals/core/printer/paper_source.dart';
import 'package:laundrypro_uae/peripherals/core/printer/printer_manager.dart';
import 'package:laundrypro_uae/peripherals/core/printer/printer_models.dart';
import 'package:laundrypro_uae/peripherals/core/printer/receipt_template.dart';
import 'package:laundrypro_uae/peripherals/core/scale/scale_parser.dart';
import 'package:laundrypro_uae/peripherals/core/scanner/scanner_manager.dart';
import 'package:laundrypro_uae/peripherals/core/scanner/scanner_models.dart';
import 'package:laundrypro_uae/peripherals/core/scanner/scanner_repository.dart';
import 'package:laundrypro_uae/peripherals/core/remote_sql/remote_sql_controller.dart';
import 'package:laundrypro_uae/peripherals/core/remote_sql/remote_sql_service.dart';
import 'package:laundrypro_uae/peripherals/core/remote_sql/remote_sql_state.dart';
import 'package:laundrypro_uae/peripherals/core/storage/app_database.dart';

final scannerManagerProvider = Provider<ScannerManager>((ref) {
  return ScannerManager(
    logger: ref.watch(appLoggerProvider),
    repository: ScannerRepository(logger: ref.watch(appLoggerProvider)),
  );
});

final printerManagerProvider = Provider<PrinterManager>((ref) {
  return PrinterManager(
    logger: ref.watch(appLoggerProvider),
    database: ref.watch(appDatabaseProvider),
  );
});

final machineIdentityManagerProvider = Provider<MachineIdentityManager>((ref) {
  return MachineIdentityManager(logger: ref.watch(appLoggerProvider));
});

final scannerPacketsProvider = StreamProvider<ScannerPacketModel>((ref) {
  return ref.watch(scannerManagerProvider).stream;
});

final scannerControllerProvider =
    Provider<Future<void> Function(KeyEvent)>((ref) {
  return (event) => ref.read(scannerManagerProvider).ingestKeyEvent(event);
});

final scaleParserProvider = Provider<ScaleParser>((_) => ScaleParser());

final lastScaleJsonProvider = StateProvider<String>((_) => '{}');

final printersProvider =
    FutureProvider<List<PrinterDeviceModel>>((ref) async {
  return ref.watch(printerManagerProvider).discoverWindowsPrinters();
});

final machineIdentityProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(machineIdentityManagerProvider).readIdentity();
});

final selectedPrinterProvider = StateProvider<String?>((_) => null);
final printerHostProvider = StateProvider<String>((_) => '127.0.0.1');
final printerPortProvider = StateProvider<int>((_) => 9100);

/// Connection mode for outgoing print jobs:
/// `spooler` — Windows installed printer via Win32 spooler (default)
/// `tcp`     — Direct raw socket to thermal printer (port 9100)
enum PrinterConnectionMode { spooler, tcp }

final printerConnectionModeProvider =
    StateProvider<PrinterConnectionMode>((_) => PrinterConnectionMode.spooler);

final paperSizeProvider =
    StateProvider<PaperSize>((_) => PaperSize.thermal80mm);

final printCopiesProvider = StateProvider<int>((_) => 1);

final receiptTitleProvider = StateProvider<String>((_) => 'RECEIPT');

/// Available paper trays/input sources for the currently selected Windows
/// printer (driver-reported). Auto-refreshes whenever the selection changes.
final paperSourcesProvider =
    FutureProvider.autoDispose<List<PaperSourceModel>>((ref) async {
  final printer = ref.watch(selectedPrinterProvider);
  if (printer == null || printer.trim().isEmpty) return const [];
  return ref.watch(printerManagerProvider).discoverPaperSources(printer);
});

/// User-selected tray name (advisory; honored only when driver path is used).
final selectedPaperSourceProvider = StateProvider<String?>((_) => null);

/// Arabic / RTL configuration --------------------------------------------------
///
/// `arabicCodePageProvider` — value sent via `ESC t n` when Arabic text is
/// detected on a line. 32 (WPC1256) works on most thermal printers. Common
/// alternatives are 22 (PC864), 39, or 41.
///
/// `reverseArabicRtlProvider` — when true, Arabic runs are visually reversed
/// before being sent so they appear right-to-left on paper. Modern firmware
/// usually requires this; flip it off only if Arabic text prints mirrored.

final arabicCodePageProvider = StateProvider<int>((_) => 32);
final reverseArabicRtlProvider = StateProvider<bool>((_) => true);

final printerStatusStreamProvider = StreamProvider.family
    .autoDispose<Map<String, dynamic>, String>((ref, printerName) async* {
  final manager = ref.watch(printerManagerProvider);
  while (true) {
    yield await manager.getPrinterStatus(printerName);
    await Future<void>.delayed(const Duration(seconds: 5));
  }
});

/// Live queue snapshot, refreshed every 2 seconds.
final printQueueStreamProvider =
    StreamProvider.autoDispose<List<Map<String, Object?>>>((ref) async* {
  final manager = ref.watch(printerManagerProvider);
  while (true) {
    yield await manager.queueSnapshot();
    await Future<void>.delayed(const Duration(seconds: 2));
  }
});

/// Receipt template library loaded from SQLite.
final receiptTemplatesProvider =
    FutureProvider<List<ReceiptTemplate>>((ref) async {
  return ref.watch(printerManagerProvider).templates.list();
});

class NetworkScanState {
  const NetworkScanState({
    required this.scanning,
    required this.candidates,
    this.error,
  });

  factory NetworkScanState.idle() =>
      const NetworkScanState(scanning: false, candidates: []);

  final bool scanning;
  final List<NetworkPrinterCandidate> candidates;
  final String? error;

  NetworkScanState copyWith({
    bool? scanning,
    List<NetworkPrinterCandidate>? candidates,
    String? error,
  }) {
    return NetworkScanState(
      scanning: scanning ?? this.scanning,
      candidates: candidates ?? this.candidates,
      error: error,
    );
  }
}

class NetworkScanController extends StateNotifier<NetworkScanState> {
  NetworkScanController(this._ref) : super(NetworkScanState.idle());

  final Ref _ref;

  Future<void> scan({int port = 9100}) async {
    if (state.scanning) return;
    state = state.copyWith(scanning: true, candidates: const [], error: null);
    try {
      final results = await _ref
          .read(printerManagerProvider)
          .networkDiscovery
          .scanLocalSubnets(port: port);
      state = state.copyWith(scanning: false, candidates: results);
    } catch (error) {
      state = state.copyWith(scanning: false, error: error.toString());
    }
  }

  void reset() {
    state = NetworkScanState.idle();
  }
}

final networkScanControllerProvider =
    StateNotifierProvider<NetworkScanController, NetworkScanState>((ref) {
  return NetworkScanController(ref);
});

final logsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final logger = ref.watch(appLoggerProvider);
  final controller = StreamController<List<Map<String, dynamic>>>();
  final items = <Map<String, dynamic>>[];

  void pushEntry(AppLogEntry entry) {
    items.insert(0, entry.toJson());
    if (items.length > 300) {
      items.removeLast();
    }
    controller.add(List<Map<String, dynamic>>.from(items));
  }

  final sub = logger.stream.listen(pushEntry);
  ref.onDispose(() async {
    await sub.cancel();
    await controller.close();
  });
  yield* controller.stream;
});

final rawJsonEncoderProvider =
    Provider<JsonEncoder>((_) => const JsonEncoder.withIndent('  '));

/// Runtime MySQL connection (SQL tab) ----------------------------------------

final remoteSqlServiceProvider = Provider<RemoteSqlService>((ref) {
  final service = RemoteSqlService(logger: ref.watch(appLoggerProvider));
  ref.onDispose(service.disconnect);
  return service;
});

final remoteSqlControllerProvider =
    StateNotifierProvider<RemoteSqlController, RemoteSqlState>((ref) {
  return RemoteSqlController(ref.watch(remoteSqlServiceProvider));
});
