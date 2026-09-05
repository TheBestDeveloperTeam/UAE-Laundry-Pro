import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:laundrypro_uae/peripherals/core/printer/network_printer_discovery.dart';
import 'package:laundrypro_uae/peripherals/features/shared/providers/app_providers.dart';

class NetworkScanDialog extends ConsumerStatefulWidget {
  const NetworkScanDialog({super.key});

  static Future<NetworkPrinterCandidate?> show(BuildContext context) {
    return showDialog<NetworkPrinterCandidate>(
      context: context,
      builder: (_) => const NetworkScanDialog(),
    );
  }

  @override
  ConsumerState<NetworkScanDialog> createState() => _NetworkScanDialogState();
}

class _NetworkScanDialogState extends ConsumerState<NetworkScanDialog> {
  int _port = 9100;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(networkScanControllerProvider.notifier).scan(port: _port);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(networkScanControllerProvider);
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
                      'Network Printer Scan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      initialValue: '$_port',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) =>
                          setState(() => _port = int.tryParse(v) ?? 9100),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: scan.scanning
                        ? null
                        : () => ref
                            .read(networkScanControllerProvider.notifier)
                            .scan(port: _port),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (scan.scanning) const LinearProgressIndicator(),
              if (scan.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Scan error: ${scan.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              Expanded(
                child: scan.candidates.isEmpty
                    ? Center(
                        child: Text(
                          scan.scanning
                              ? 'Scanning local subnets...'
                              : 'No network printers found on port $_port.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: scan.candidates.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final candidate = scan.candidates[index];
                          return ListTile(
                            leading: const Icon(Icons.lan),
                            title: Text('${candidate.host}:${candidate.port}'),
                            subtitle:
                                Text('Latency: ${candidate.responseMs} ms'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).pop(candidate),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
