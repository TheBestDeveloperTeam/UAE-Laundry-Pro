import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:laundrypro_uae/peripherals/core/logging/app_logger.dart';
import 'package:laundrypro_uae/peripherals/core/scanner/scanner_event_bus.dart';
import 'package:laundrypro_uae/peripherals/core/scanner/scanner_models.dart';
import 'package:laundrypro_uae/peripherals/core/scanner/scanner_repository.dart';

class ScannerManager {
  ScannerManager({
    required AppLogger logger,
    ScannerEventBus? eventBus,
    ScannerRepository? repository,
  })  : _logger = logger,
        _eventBus = eventBus ?? ScannerEventBus(),
        _repository = repository;

  final AppLogger _logger;
  final ScannerEventBus _eventBus;
  final ScannerRepository? _repository;
  final StringBuffer _buffer = StringBuffer();
  DateTime? _firstTs;
  DateTime? _lastTs;
  Duration burstTimeout = const Duration(milliseconds: 75);
  Duration maxHumanInterval = const Duration(milliseconds: 35);

  Stream<ScannerPacketModel> get stream => _eventBus.stream;

  Future<void> ingestKeyEvent(KeyEvent event) async {
    if (event is! KeyDownEvent) return;
    final now = DateTime.now();
    final label = event.logicalKey.keyLabel;
    if (label.isEmpty && event.logicalKey != LogicalKeyboardKey.enter) {
      return;
    }

    if (_lastTs != null && now.difference(_lastTs!) > burstTimeout) {
      _reset();
    }

    _firstTs ??= now;
    _lastTs = now;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.tab) {
      await _emitIfScannerLike();
      _reset();
      return;
    }

    _buffer.write(label);
  }

  Future<void> _emitIfScannerLike() async {
    if (_buffer.isEmpty || _firstTs == null || _lastTs == null) return;
    final value = _buffer.toString();
    final elapsed = _lastTs!.difference(_firstTs!);
    final avgMs = elapsed.inMilliseconds / value.length.clamp(1, 9999);
    if (avgMs > maxHumanInterval.inMilliseconds) {
      return;
    }

    final bytes = utf8.encode(value);
    final packet = ScannerPacketModel(
      deviceName: 'KeyboardWedge',
      deviceType: 'HID',
      connectionType: 'USB/HID',
      rawData: value,
      decodedValue: value,
      hexData: bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' '),
      timestamp: DateTime.now().toUtc(),
      latencyMs: elapsed.inMilliseconds,
    );
    _eventBus.publish(packet);
    await _repository?.persistPacket(packet);
    await _logger.info(
      'Scanner packet received',
      scope: 'scanner',
      payload: packet.toJson(),
    );
  }

  void _reset() {
    _buffer.clear();
    _firstTs = null;
    _lastTs = null;
  }
}
