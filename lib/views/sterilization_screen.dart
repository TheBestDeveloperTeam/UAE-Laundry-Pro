import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sterilization_service.dart';

class SterilizationScreen extends ConsumerStatefulWidget {
  const SterilizationScreen({Key? key}) : super(key: key);
  @override
  ConsumerState<SterilizationScreen> createState() => _SterilizationScreenState();
}

class _SterilizationScreenState extends ConsumerState<SterilizationScreen> {
  final _lotController = TextEditingController();
  final _orderController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _createBatch() async {
    setState(() => _isLoading = true);
    try {
      final s = ref.read(sterilizationServiceProvider);
      await s.batchCreate({
        'lot_number': _lotController.text,
        'expiry_date': '2029-12-31',
        'origin_sales_order_id': int.tryParse(_orderController.text) ?? 1
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch Lot Created')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sterilization & Compliance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _lotController,
              decoration: const InputDecoration(labelText: 'Lot Number'),
            ),
            TextField(
              controller: _orderController,
              decoration: const InputDecoration(labelText: 'Origin Sales Order ID'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _createBatch,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Create Batch Lot'),
            ),
          ],
        ),
      ),
    );
  }
}

