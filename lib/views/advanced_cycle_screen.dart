import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/empty_state.dart';
import '../services/advanced_cycle_service.dart';

class AdvancedCycleScreen extends ConsumerStatefulWidget {
  const AdvancedCycleScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdvancedCycleScreen> createState() => _AdvancedCycleScreenState();
}

class _AdvancedCycleScreenState extends ConsumerState<AdvancedCycleScreen> {
  final _saleOrderIdController = TextEditingController();
  final _cyclePresetIdController = TextEditingController();
  final _equipmentIdController = TextEditingController();
  final _operatorIdController = TextEditingController();

  final _runIdController = TextEditingController();
  final _readingController = TextEditingController();
  String? _metricType = 'pH';

  Future<void> _startCycle() async {
    try {
      final svc = ref.read(advancedCycleServiceProvider);
      await svc.startCycle({
        'sale_id': _saleOrderIdController.text,
        'preset_id': _cyclePresetIdController.text,
        'equipment_id': _equipmentIdController.text,
        'operator_id': _operatorIdController.text,
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cycle Started')));
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \')));
      }
    }
  }

  Future<void> _recordMetric() async {
    try {
      final svc = ref.read(advancedCycleServiceProvider);
      await svc.processLog(_runIdController.text, {
        'step_name': _metricType,
        'metrics': {'value': _readingController.text},
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Metric Recorded')));
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Cycles'),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Running Cycles'),
                Tab(text: 'Start New Cycle'),
                Tab(text: 'Process Logs'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildRunningCyclesTab(),
                  _buildStartCycleTab(),
                  _buildProcessLogsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunningCyclesTab() {
    return const Center(
      child: EmptyState(
        icon: Icons.loop,
        title: 'No Running Cycles',
        message: 'There are no active advanced cycles running right now.',
      ),
    );
  }

  Widget _buildStartCycleTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Start a new advanced garment cycle with calibrated equipment.'),
            const SizedBox(height: 16),
            TextFormField(controller: _saleOrderIdController, decoration: const InputDecoration(labelText: 'Sale Order ID')),
            const SizedBox(height: 16),
            TextFormField(controller: _cyclePresetIdController, decoration: const InputDecoration(labelText: 'Cycle Preset ID')),
            const SizedBox(height: 16),
            TextFormField(controller: _equipmentIdController, decoration: const InputDecoration(labelText: 'Equipment ID')),
            const SizedBox(height: 16),
            TextFormField(controller: _operatorIdController, decoration: const InputDecoration(labelText: 'Operator ID')),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _startCycle, child: const Text('START CYCLE')),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessLogsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Record pH or Temperature metrics for an active cycle run.'),
          const SizedBox(height: 16),
          TextFormField(controller: _runIdController, decoration: const InputDecoration(labelText: 'Cycle Run ID')),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Metric Type'),
            value: _metricType,
            items: const [
              DropdownMenuItem(value: 'pH', child: Text('pH Level')),
              DropdownMenuItem(value: 'temperature', child: Text('Temperature (°C)')),
            ],
            onChanged: (val) => setState(() => _metricType = val),
          ),
          const SizedBox(height: 16),
          TextFormField(controller: _readingController, decoration: const InputDecoration(labelText: 'Reading Value')),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _recordMetric, child: const Text('RECORD METRIC')),
        ],
      ),
    );
  }
}
