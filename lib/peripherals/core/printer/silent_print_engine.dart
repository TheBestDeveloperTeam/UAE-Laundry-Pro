import 'dart:io';

import 'package:laundrypro_uae/peripherals/core/logging/app_logger.dart';

class SilentPrintEngine {
  SilentPrintEngine({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;

  Future<void> printTcp({
    required String host,
    required int port,
    required List<int> payload,
  }) async {
    final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 3));
    socket.add(payload);
    await socket.flush();
    await socket.close();
    await _logger.info(
      'Silent print completed',
      scope: 'silent_print_engine',
      payload: {'host': host, 'port': port, 'bytes': payload.length},
    );
  }
}
