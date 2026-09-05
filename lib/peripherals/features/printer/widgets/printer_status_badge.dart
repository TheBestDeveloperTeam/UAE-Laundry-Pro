import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:laundrypro_uae/peripherals/features/shared/providers/app_providers.dart';

class PrinterStatusBadge extends ConsumerWidget {
  const PrinterStatusBadge({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(printerStatusStreamProvider(name));
    return status.when(
      data: (data) {
        final statusText =
            (data['Status'] ?? data['status'] ?? 'Unknown').toString();
        final jobs = data['JobCount'] ?? data['jobCount'] ?? 0;
        final error = data['error'];
        final color = _statusColor(statusText, hasError: error != null);
        return Card(
          color: color.withValues(alpha: 0.12),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: color, radius: 10),
            title: Text('Status: $statusText'),
            subtitle: Text(
              error != null
                  ? 'Error: $error'
                  : 'Jobs in queue: $jobs · Port: ${data['PortName'] ?? '-'} · Driver: ${data['DriverName'] ?? '-'}',
            ),
          ),
        );
      },
      loading: () => const Card(
        child: ListTile(
          leading: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('Checking printer status...'),
        ),
      ),
      error: (e, _) => Card(
        child: ListTile(
          leading: const Icon(Icons.error, color: Colors.redAccent),
          title: Text('Status check failed: $e'),
        ),
      ),
    );
  }

  Color _statusColor(String status, {required bool hasError}) {
    if (hasError) return Colors.redAccent;
    final s = status.toLowerCase();
    if (s.contains('normal') || s.contains('idle') || s.contains('ready')) {
      return Colors.green;
    }
    if (s.contains('offline') || s.contains('error') || s.contains('jam')) {
      return Colors.redAccent;
    }
    if (s.contains('busy') ||
        s.contains('printing') ||
        s.contains('paused')) {
      return Colors.orange;
    }
    return Colors.grey;
  }
}
