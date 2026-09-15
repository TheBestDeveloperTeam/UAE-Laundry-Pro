import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/rfid_service.dart';

class RfidTrackingScreen extends ConsumerStatefulWidget {
  const RfidTrackingScreen({Key? key}) : super(key: key);
  @override
  ConsumerState<RfidTrackingScreen> createState() => _RfidTrackingScreenState();
}

class _RfidTrackingScreenState extends ConsumerState<RfidTrackingScreen> {
  bool _isScanning = false;
  String _statusMessage = 'Ready to scan';

  Future<void> _scanTags() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning tags...';
    });
    try {
      final s = ref.read(rfidServiceProvider);
      // Let backend use DummyAdapter
      final result = await s.scanTags([]);
      if (mounted) {
        setState(() {
          _statusMessage = 'Scanned \ tags. Transitioned \ items.';
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scan complete')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Scan failed: \';
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \')));
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RFID Batch Tracking'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sensors,
              size: 100,
              color: _isScanning ? Colors.blue : Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(_statusMessage, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isScanning ? null : _scanTags,
              child: const Text('Simulate Bulk Scan'),
            ),
          ],
        ),
      ),
    );
  }
}

