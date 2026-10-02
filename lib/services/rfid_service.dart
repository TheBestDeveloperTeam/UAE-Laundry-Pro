import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final rfidServiceProvider = Provider((ref) => RfidService(ref.read(apiClientProvider)));

enum RfidReaderMode {
  apiBridge, // Calls backend PHP adapter
  directTcp, // Connects directly via TCP socket to fixed tunnel UHF reader (LLRP / raw ASCII)
}

class RfidService {
  final ApiClient _api;

  RfidService(this._api);

  /// Scan tags via backend API (or simulated fallback)
  Future<Map<String, dynamic>> scanTags(List<String> tags) async {
    final res = await _api.post('/rfid/scan', data: {'epc_tags': tags});
    return res['data'] ?? {};
  }

  /// Direct TCP socket connector for fixed industrial UHF tunnel antenna
  /// Defaults to standard Impinj / Zebra FX9600 reader IP port (e.g. 5084 or raw 9090)
  Future<List<Map<String, dynamic>>> scanDirectTcp({
    String host = '192.168.1.180',
    int port = 5084,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final List<Map<String, dynamic>> results = [];
    Socket? socket;

    try {
      socket = await Socket.connect(host, port, timeout: timeout);
      // Send reader tag inventory command (Standard Impinj / Alien ASCII command: "t\r\n")
      socket.write('t\r\n');
      await socket.flush();

      final completer = Completer<List<Map<String, dynamic>>>();
      final buffer = StringBuffer();

      final subscription = socket.listen(
        (data) {
          final chunk = utf8.decode(data, allowMalformed: true);
          buffer.write(chunk);

          // Parse EPC tags from stream lines
          final lines = buffer.toString().split('\n');
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.startsWith('TAG:') || trimmed.length >= 24) {
              final epc = trimmed.replaceAll('TAG:', '').trim();
              if (epc.isNotEmpty && !results.any((r) => r['epc'] == epc)) {
                results.add({
                  'epc': epc,
                  'rssi': -45,
                  'antenna_port': 1,
                  'read_count': 1,
                  'detected_at': DateTime.now().toIso8601String(),
                });
              }
            }
          }
        },
        onError: (err) {
          if (!completer.isCompleted) completer.complete(results);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(results);
        },
        cancelOnError: true,
      );

      // Wait up to scan window duration then conclude
      await Future.delayed(timeout);
      await subscription.cancel();
      socket.destroy();
      return results;
    } catch (_) {
      socket?.destroy();
      // On connection timeout or unreachable IP, return empty list gracefully
      return results;
    }
  }
}
