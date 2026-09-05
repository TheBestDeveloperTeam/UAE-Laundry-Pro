import 'dart:io';

import 'package:laundrypro_uae/peripherals/core/logging/app_logger.dart';

class NetworkPrinterCandidate {
  NetworkPrinterCandidate({
    required this.host,
    required this.port,
    required this.responseMs,
  });

  final String host;
  final int port;
  final int responseMs;

  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'responseMs': responseMs,
      };
}

/// Scans the local IPv4 subnets for hosts that have the given port open.
/// Default targets the common RAW thermal printer port (9100).
class NetworkPrinterDiscovery {
  NetworkPrinterDiscovery({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;

  Future<List<NetworkPrinterCandidate>> scanLocalSubnets({
    int port = 9100,
    Duration timeout = const Duration(milliseconds: 250),
    int concurrentScans = 64,
  }) async {
    final candidates = <NetworkPrinterCandidate>[];
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
      includeLoopback: false,
    );

    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (addr.isLoopback) continue;
        final parts = addr.address.split('.');
        if (parts.length != 4) continue;
        final base = '${parts[0]}.${parts[1]}.${parts[2]}.';
        final targets = <int>[for (var i = 1; i < 255; i++) i];

        for (var offset = 0; offset < targets.length; offset += concurrentScans) {
          final batch = targets.skip(offset).take(concurrentScans).toList();
          final batchResults = await Future.wait(
            batch.map((suffix) => _probe('$base$suffix', port, timeout)),
            eagerError: false,
          );
          for (final candidate in batchResults.whereType<NetworkPrinterCandidate>()) {
            candidates.add(candidate);
          }
        }
      }
    }

    await _logger.info(
      'Network printer scan complete',
      scope: 'printer',
      payload: {
        'port': port,
        'discovered': candidates.length,
      },
    );

    return candidates;
  }

  Future<NetworkPrinterCandidate?> _probe(
    String host,
    int port,
    Duration timeout,
  ) async {
    final stopwatch = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
      stopwatch.stop();
      return NetworkPrinterCandidate(
        host: host,
        port: port,
        responseMs: stopwatch.elapsedMilliseconds,
      );
    } catch (_) {
      return null;
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
    }
  }
}
