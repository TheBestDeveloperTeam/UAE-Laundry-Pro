import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:laundrypro_uae/peripherals/core/printer/receipt_template.dart';
import 'package:laundrypro_uae/peripherals/features/shared/providers/app_providers.dart';

class TemplatePickerDialog extends ConsumerWidget {
  const TemplatePickerDialog({super.key});

  static Future<ReceiptTemplate?> show(BuildContext context) {
    return showDialog<ReceiptTemplate>(
      context: context,
      builder: (_) => const TemplatePickerDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(receiptTemplatesProvider);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 540),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Saved Receipt Templates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => ref.invalidate(receiptTemplatesProvider),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: templates.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(
                        child: Text('No templates saved yet.'),
                      );
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final t = items[index];
                        return ListTile(
                          title: Text(t.name),
                          subtitle: Text(
                            '${t.lines.length} line(s) · ${t.paper.label} · '
                            '${t.createdAt.toIso8601String()}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Delete template',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await ref
                                  .read(printerManagerProvider)
                                  .templates
                                  .delete(t.id);
                              ref.invalidate(receiptTemplatesProvider);
                            },
                          ),
                          onTap: () => Navigator.of(context).pop(t),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Failed: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
