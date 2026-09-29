import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:laundrypro_uae/peripherals/core/scanner/scanner_models.dart';
import 'package:laundrypro_uae/peripherals/features/shared/providers/app_providers.dart';

/// Dedicated barcode scanner screen. Keyboard-wedge input is handled by the
/// shell-level [KeyboardListener]; this tab only displays scan results.
///
/// Auto-focus is intentionally disabled to avoid focus-tree conflicts on tab load.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _displayValue = '';
  String _lastJson = '{}';
  final List<ScannerPacketModel> _history = [];
  int _scanCount = 0;

  @override
  void initState() {
    super.initState();
    ref.listenManual(scannerPacketsProvider, (previous, next) {
      next.whenData((packet) {
        if (mounted) {
          _applyScan(packet);
        }
      });
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _clearBeforeNewScan() {
    _inputController.clear();
    setState(() {
      _displayValue = '';
      _lastJson = '{}';
    });
  }

  void _applyScan(ScannerPacketModel packet) {
    setState(() {
      _inputController.text = packet.decodedValue;
      _displayValue = packet.decodedValue;
      _lastJson = packet.asPrettyJson();
      _scanCount++;
      _history.insert(0, packet);
      if (_history.length > 50) {
        _history.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _clearBeforeNewScan,
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Barcode Scanner',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Chip(
                avatar: const Icon(Icons.qr_code_scanner, size: 16),
                label: Text('Scans: $_scanCount'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Keyboard-wedge / HID scanners are supported via the app-wide listener. '
            'Each new scan replaces the previous value below.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _inputController,
            readOnly: true,
            showCursor: false,
            enableInteractiveSelection: true,
            decoration: InputDecoration(
              labelText: 'Scanned value',
              hintText: 'Waiting for scan...',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.clear),
                onPressed: _clearBeforeNewScan,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(
                  alpha: 0.35,
                ),
            child: ListTile(
              leading: const Icon(Icons.document_scanner),
              title: Text(
                _displayValue.isEmpty ? 'No scan yet' : _displayValue,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Latest decoded barcode'),
            ),
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            title: const Text('Raw packet JSON'),
            initiallyExpanded: false,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  _lastJson,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Scan history (${_history.length})',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_history.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('History will appear after scans.')),
              ),
            )
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length.clamp(0, 20),
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final packet = _history[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(
                      packet.decodedValue,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    subtitle: Text(
                      '${packet.latencyMs} ms · '
                      '${packet.timestamp.toIso8601String()}',
                    ),
                    onTap: () => _applyScan(packet),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
