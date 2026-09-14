import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/empty_state.dart';

class AdvancedCycleScreen extends ConsumerStatefulWidget {
  const AdvancedCycleScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdvancedCycleScreen> createState() => _AdvancedCycleScreenState();
}

class _AdvancedCycleScreenState extends ConsumerState<AdvancedCycleScreen> {
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
            TextFormField(
              decoration: const InputDecoration(labelText: 'Sale Order ID'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Cycle Preset ID'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Equipment ID'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Operator ID'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text('START CYCLE'),
            ),
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
          TextFormField(
            decoration: const InputDecoration(labelText: 'Cycle Run ID'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Metric Type'),
            items: const [
              DropdownMenuItem(value: 'pH', child: Text('pH Level')),
              DropdownMenuItem(value: 'temperature', child: Text('Temperature (°C)')),
            ],
            onChanged: (val) {},
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Reading Value'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            child: const Text('RECORD METRIC'),
          ),
        ],
      ),
    );
  }
}
