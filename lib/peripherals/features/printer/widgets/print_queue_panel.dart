import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:laundrypro_uae/peripherals/features/shared/providers/app_providers.dart';

class PrintQueuePanel extends ConsumerWidget {
  const PrintQueuePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(printQueueStreamProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Print Queue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(printQueueStreamProvider),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Auto-refreshing every 2 seconds. Failed/queued jobs can be retried '
          'or removed individually.',
        ),
        const SizedBox(height: 12),
        queue.when(
          data: (rows) {
            if (rows.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Queue is empty.')),
              );
            }
            return Card(
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++)
                    _QueueRow(row: rows[i], showDivider: i != rows.length - 1),
                ],
              ),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Failed: $e'),
        ),
      ],
    );
  }
}

class _QueueRow extends ConsumerWidget {
  const _QueueRow({required this.row, required this.showDivider});

  final Map<String, Object?> row;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = row['id']!.toString();
    final printer = row['printer_name']?.toString() ?? '-';
    final connection = row['connection_type']?.toString() ?? '-';
    final status = row['status']?.toString() ?? '-';
    final retries = (row['retries'] as int?) ?? 0;
    final createdAt = row['created_at']?.toString() ?? '-';

    final color = switch (status) {
      'printed' => Colors.green,
      'failed' => Colors.redAccent,
      _ => Colors.orange,
    };

    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(backgroundColor: color, radius: 8),
          title: Text('$printer · $connection'),
          subtitle: Text(
            'Status: $status · Retries: $retries · $createdAt',
          ),
          trailing: Wrap(
            spacing: 4,
            children: [
              if (status != 'printed')
                IconButton(
                  tooltip: 'Retry',
                  icon: const Icon(Icons.replay),
                  onPressed: () async {
                    await ref
                        .read(printerManagerProvider)
                        .retryQueuedJob(id: id);
                    ref.invalidate(printQueueStreamProvider);
                  },
                ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await ref
                      .read(printerManagerProvider)
                      .deleteQueuedJob(id: id);
                  ref.invalidate(printQueueStreamProvider);
                },
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
