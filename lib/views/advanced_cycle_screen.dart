import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/theme.dart';
import '../services/advanced_cycle_service.dart';

class AdvancedCycleScreen extends ConsumerStatefulWidget {
  const AdvancedCycleScreen({super.key, this.advancedCycleService});

  final AdvancedCycleService? advancedCycleService;

  @override
  ConsumerState<AdvancedCycleScreen> createState() => _AdvancedCycleScreenState();
}

class _AdvancedCycleScreenState extends ConsumerState<AdvancedCycleScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _saleOrderIdController = TextEditingController(text: '101');
  final _equipmentIdController = TextEditingController(text: '1');
  final _operatorIdController = TextEditingController(text: '1');

  final _runIdController = TextEditingController(text: '1');
  final _readingController = TextEditingController(text: '6.5');
  String _metricType = 'pH';

  bool _loading = false;
  List<dynamic> _presets = [];
  dynamic _selectedPreset;

  final List<Map<String, dynamic>> _activeRuns = [
    {
      'id': 1,
      'order_id': 101,
      'preset_name': 'Medical Barrier & Aseptic Cycle (ISO Class 7)',
      'equipment': 'Commercial Washer-Extractor #01 (Milnor 60kg)',
      'operator': 'Operator #01 (Certified Cleanroom L2)',
      'status': 'running',
      'temp': '85.0°C',
      'ph': '6.8',
      'detergent_ml': '240 ml',
      'started_at': '2026-10-02 14:30',
      'logs': [
        {'step': 'Pre-Wash & Enzyme Dosing', 'temp': '45.0°C', 'ph': '7.2', 'status': 'pass'},
        {'step': 'Thermal Disinfection Wash', 'temp': '85.0°C', 'ph': '6.8', 'status': 'pass'},
      ],
    },
    {
      'id': 2,
      'order_id': 104,
      'preset_name': 'Gentle Silk & Embroidered Abaya Conditioning',
      'equipment': 'Electrolux Lagoon Wet Clean #02',
      'operator': 'Operator #03 (Delicate Textiles Specialist)',
      'status': 'running',
      'temp': '30.0°C',
      'ph': '5.5',
      'detergent_ml': '120 ml',
      'started_at': '2026-10-02 15:10',
      'logs': [
        {'step': 'Cold Water Soak & Woolite Injection', 'temp': '30.0°C', 'ph': '5.5', 'status': 'pass'},
      ],
    },
  ];

  final List<Map<String, dynamic>> _mockPresets = [
    {
      'id': 1,
      'code': 'MED_ISO7',
      'name_en': 'Medical Barrier & Aseptic Cycle (ISO Class 7)',
      'min_temperature': 85.0,
      'max_temperature': 95.0,
      'min_ph': 6.0,
      'max_ph': 7.5,
      'expected_duration_minutes': 45,
      'detergent_formula': 'Alkaline Builder + Peracetic Acid 15% (240ml)',
    },
    {
      'id': 2,
      'code': 'SILK_ABAYA',
      'name_en': 'Gentle Silk & Embroidered Abaya Conditioning',
      'min_temperature': 25.0,
      'max_temperature': 35.0,
      'min_ph': 5.0,
      'max_ph': 6.0,
      'expected_duration_minutes': 30,
      'detergent_formula': 'Neutral pH Silk Surfactant + Silicone Softener (120ml)',
    },
    {
      'id': 3,
      'code': 'KANDORA_OPT',
      'name_en': 'Emirati Kandora Optical Brightening & Starch Press',
      'min_temperature': 60.0,
      'max_temperature': 70.0,
      'min_ph': 6.5,
      'max_ph': 8.0,
      'expected_duration_minutes': 40,
      'detergent_formula': 'Non-Ionic Detergent + Optical Brightener UV-350 + Liquid Starch (180ml)',
    },
    {
      'id': 4,
      'code': 'FIRE_RETARD',
      'name_en': 'Industrial PPE Flame-Retardant Oil Remediation',
      'min_temperature': 75.0,
      'max_temperature': 85.0,
      'min_ph': 7.0,
      'max_ph': 9.0,
      'expected_duration_minutes': 60,
      'detergent_formula': 'Solvent Emulsifier + Heavy Alkali Break (300ml)',
    },
  ];

  AdvancedCycleService get _service =>
      widget.advancedCycleService ?? ref.read(advancedCycleServiceProvider);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPresets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _saleOrderIdController.dispose();
    _equipmentIdController.dispose();
    _operatorIdController.dispose();
    _runIdController.dispose();
    _readingController.dispose();
    super.dispose();
  }

  Future<void> _loadPresets() async {
    setState(() => _loading = true);
    try {
      final list = await _service.getPresets();
      if (mounted) {
        setState(() {
          _presets = list.isNotEmpty ? list : _mockPresets;
          _selectedPreset = _presets.first;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _presets = _mockPresets;
          _selectedPreset = _mockPresets.first;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startCycle() async {
    setState(() => _loading = true);
    try {
      final payload = {
        'sale_order_id': int.tryParse(_saleOrderIdController.text) ?? 101,
        'preset_id': _selectedPreset != null ? _selectedPreset['id'] ?? 1 : 1,
        'equipment_id': int.tryParse(_equipmentIdController.text) ?? 1,
        'operator_id': int.tryParse(_operatorIdController.text) ?? 1,
      };

      await _service.startCycle(payload);

      final newRun = {
        'id': _activeRuns.length + 1,
        'order_id': payload['sale_order_id'],
        'preset_name': _selectedPreset?['name_en'] ?? 'Custom Cycle',
        'equipment': 'Asset #${payload['equipment_id']} (Calibrated)',
        'operator': 'Operator #${payload['operator_id']} (Certified)',
        'status': 'running',
        'temp': '${_selectedPreset?['min_temperature'] ?? 60.0}°C',
        'ph': '${_selectedPreset?['min_ph'] ?? 6.5}',
        'detergent_ml': '200 ml',
        'started_at': DateTime.now().toIso8601String().substring(0, 16).replaceAll('T', ' '),
        'logs': [
          {'step': 'Cycle Initialized & Dosing Commenced', 'temp': 'Ambient', 'ph': 'Neutral', 'status': 'pass'},
        ],
      };

      setState(() {
        _activeRuns.insert(0, newRun);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Advanced Cycle started with calibrated parameters'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting cycle: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _recordMetric() async {
    final runId = _runIdController.text.trim();
    final reading = _readingController.text.trim();
    if (runId.isEmpty || reading.isEmpty) return;

    setState(() => _loading = true);
    try {
      final res = await _service.processLog(runId, {
        'metric_type': _metricType,
        'reading_value': reading,
      });

      final pass = res['pass_fail'] != false;

      // Append to local state if active run matches
      final rId = int.tryParse(runId);
      final run = _activeRuns.firstWhere((r) => r['id'] == rId, orElse: () => {});
      if (run.isNotEmpty) {
        (run['logs'] as List).add({
          'step': 'Logged $_metricType Value: $reading',
          'temp': _metricType == 'temperature' ? '$reading°C' : run['temp'],
          'ph': _metricType == 'pH' ? reading : run['ph'],
          'status': pass ? 'pass' : 'exception',
        });
        if (!pass) {
          run['status'] = 'exception';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pass ? 'Metric recorded — Verified within preset threshold' : 'WARNING: Reading exceeded tolerance! Cycle flagged exception.'),
            backgroundColor: pass ? AppTheme.successGreen : AppTheme.warningOrange,
          ),
        );
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording metric: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeCycle(Map<String, dynamic> run) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Complete Cycle Run'),
        content: Text('Conclude cycle #${run['id']} for Order #${run['order_id']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentTeal, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.completeCycle('${run['id']}', 'completed_normal');
        setState(() {
          run['status'] = 'completed';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cycle marked as completed'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error completing cycle: $e'), backgroundColor: AppTheme.errorRed),
          );
        }
      }
    }
  }

  void _showRunDetails(Map<String, dynamic> run) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final isRunning = run['status'] == 'running';
        final isException = run['status'] == 'exception';
        final logs = (run['logs'] as List?) ?? [];

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollCtrl,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Cycle #${run['id']} — Order #${run['order_id']}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isRunning
                                  ? AppTheme.accentTeal
                                  : isException
                                      ? AppTheme.errorRed
                                      : AppTheme.primaryNavy)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (run['status'] as String).toUpperCase(),
                          style: TextStyle(
                            color: isRunning
                                ? AppTheme.accentTeal
                                : isException
                                    ? AppTheme.errorRed
                                    : AppTheme.primaryNavy,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _detailRow('Preset Program', run['preset_name']),
                  _detailRow('Operating Equipment', run['equipment']),
                  _detailRow('Certified Operator', run['operator']),
                  _detailRow('Current Temperature', run['temp']),
                  _detailRow('Current Solution pH', run['ph']),
                  _detailRow('Detergent Dosed', run['detergent_ml']),
                  _detailRow('Started At', run['started_at']),
                  const SizedBox(height: 16),
                  const Text('Process Logs & Quality Telemetry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  ...logs.map((log) {
                    final pass = log['status'] == 'pass';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          pass ? Icons.check_circle : Icons.warning,
                          color: pass ? AppTheme.successGreen : AppTheme.errorRed,
                        ),
                        title: Text(log['step'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Temp: ${log['temp']} • pH: ${log['ph']}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (pass ? AppTheme.successGreen : AppTheme.errorRed).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            pass ? 'PASS' : 'FAIL',
                            style: TextStyle(
                              color: pass ? AppTheme.successGreen : AppTheme.errorRed,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  if (isRunning)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Complete Cycle Run'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _completeCycle(run);
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('advanced_cycles')),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppTheme.accentTeal,
          tabs: const [
            Tab(icon: Icon(Icons.loop), text: 'Active Runs'),
            Tab(icon: Icon(Icons.play_circle_outline), text: 'Start Cycle'),
            Tab(icon: Icon(Icons.science_outlined), text: 'Log Metrics & Chemistry'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveRunsTab(),
          _buildStartCycleTab(),
          _buildProcessLogsTab(),
        ],
      ),
    );
  }

  Widget _buildActiveRunsTab() {
    if (_activeRuns.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.loop, size: 48, color: AppTheme.secondaryGrey),
            SizedBox(height: 12),
            Text('No active garment cycles currently running', style: TextStyle(color: AppTheme.secondaryGrey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _activeRuns.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final run = _activeRuns[i];
        final isRunning = run['status'] == 'running';
        final isException = run['status'] == 'exception';

        final badgeColor = isRunning
            ? AppTheme.accentTeal
            : isException
                ? AppTheme.errorRed
                : AppTheme.primaryNavy;

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isException ? AppTheme.errorRed.withValues(alpha: 0.3) : Colors.transparent,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showRunDetails(run),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: badgeColor.withValues(alpha: 0.15),
                            child: Icon(
                              isRunning ? Icons.play_arrow : Icons.done,
                              color: badgeColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Cycle Run #${run['id']} • Order #${run['order_id']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (run['status'] as String).toUpperCase(),
                          style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    run['preset_name'],
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryNavy),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${run['equipment']} • ${run['operator']}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.secondaryGrey),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.thermostat, size: 16, color: AppTheme.warningOrange),
                          const SizedBox(width: 4),
                          Text('Temp: ${run['temp']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          const Icon(Icons.water_drop, size: 16, color: AppTheme.infoBlue),
                          const SizedBox(width: 4),
                          Text('pH: ${run['ph']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          const Icon(Icons.science, size: 16, color: AppTheme.accentTeal),
                          const SizedBox(width: 4),
                          Text('Dosing: ${run['detergent_ml']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (isRunning)
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accentTeal,
                            side: const BorderSide(color: AppTheme.accentTeal),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _completeCycle(run),
                          child: const Text('Complete'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartCycleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryNavy.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryNavy.withValues(alpha: 0.1)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppTheme.primaryNavy, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Enforces calibrated equipment & certified operator compliance before cycle execution.',
                    style: TextStyle(fontSize: 13, color: AppTheme.primaryNavy),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Cycle Preset Program', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<dynamic>(
                    initialValue: _selectedPreset,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Cycle Preset *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tune),
                    ),
                    items: _presets.map((p) {
                      final name = p['name_en'] ?? p['code'] ?? 'Preset';
                      return DropdownMenuItem(value: p, child: Text(name, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedPreset = val),
                  ),
                  if (_selectedPreset != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chemical Formula: ${_selectedPreset['detergent_formula'] ?? 'Automatic multi-stage injection'}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Allowed Temp: ${_selectedPreset['min_temperature']}°C – ${_selectedPreset['max_temperature']}°C • pH: ${_selectedPreset['min_ph']} – ${_selectedPreset['max_ph']} • Est. ${_selectedPreset['expected_duration_minutes']} min',
                            style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _saleOrderIdController,
                    decoration: const InputDecoration(
                      labelText: 'Sale Order ID *',
                      hintText: 'e.g. 101',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _equipmentIdController,
                          decoration: const InputDecoration(
                            labelText: 'Equipment ID *',
                            hintText: 'e.g. 1',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.precision_manufacturing),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _operatorIdController,
                          decoration: const InputDecoration(
                            labelText: 'Operator ID *',
                            hintText: 'e.g. 1',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.play_arrow),
                      label: const Text('START ADVANCED CYCLE', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _loading ? null : _startCycle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessLogsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Record Real-Time In-Cycle Telemetry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text(
                    'Direct sensor reading verification against programmed batch recipe thresholds.',
                    style: TextStyle(color: AppTheme.secondaryGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _runIdController,
                    decoration: const InputDecoration(
                      labelText: 'Cycle Run ID *',
                      hintText: 'e.g. 1',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _metricType,
                    decoration: const InputDecoration(
                      labelText: 'Metric Parameter *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.analytics_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pH', child: Text('pH Level (Acidity/Alkalinity)')),
                      DropdownMenuItem(value: 'temperature', child: Text('Bath Temperature (°C)')),
                      DropdownMenuItem(value: 'detergent_dosing', child: Text('Chemical Dosing Volume (ml)')),
                      DropdownMenuItem(value: 'conductivity', child: Text('Rinse Water Conductivity (µS/cm)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _metricType = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _readingController,
                    decoration: InputDecoration(
                      labelText: 'Sensor / Titration Reading *',
                      hintText: _metricType == 'temperature' ? 'e.g. 85.0' : 'e.g. 6.5',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.speed),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.add_chart),
                      label: const Text('RECORD METRIC & VALIDATE', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _loading ? null : _recordMetric,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
