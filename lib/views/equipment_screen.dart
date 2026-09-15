import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/equipment_service.dart';

class EquipmentScreen extends ConsumerStatefulWidget {
  const EquipmentScreen({Key? key}) : super(key: key);
  @override
  ConsumerState<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends ConsumerState<EquipmentScreen> {
  bool _isLoading = false;
  List<dynamic> _equipmentList = [];

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    setState(() => _isLoading = true);
    try {
      final s = ref.read(equipmentServiceProvider);
      final list = await s.listAll();
      if (mounted) setState(() => _equipmentList = list);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Calibration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEquipment,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _equipmentList.length,
            itemBuilder: (context, index) {
              final eq = _equipmentList[index];
              final outOfService = eq['out_of_service'] == 1 || eq['out_of_service'] == true;
              return ListTile(
                title: Text(eq['asset_tag']),
                subtitle: Text('Type: \ - Next Due: \'),
                trailing: Chip(
                  label: Text(outOfService ? 'Out of Service' : 'Active'),
                  backgroundColor: outOfService ? Colors.red : Colors.green,
                ),
              );
            },
          ),
    );
  }
}

