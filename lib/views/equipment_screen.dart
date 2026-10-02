import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/theme.dart';
import '../models/inventory_model.dart';
import '../services/equipment_service.dart';

class EquipmentScreen extends ConsumerStatefulWidget {
  const EquipmentScreen({super.key, this.equipmentService});

  final EquipmentService? equipmentService;

  @override
  ConsumerState<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends ConsumerState<EquipmentScreen> {
  bool _isLoading = false;
  List<InventoryModel> _equipmentList = [];
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'maintenance'
  final TextEditingController _searchController = TextEditingController();

  EquipmentService get _service =>
      widget.equipmentService ?? ref.read(equipmentServiceProvider);

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEquipment() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.listAll();
      if (mounted) setState(() => _equipmentList = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<InventoryModel> get _filteredEquipment {
    return _equipmentList.where((eq) {
      final matchesSearch = _searchQuery.isEmpty ||
          (eq.assetTag?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (eq.machineType?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          eq.itemName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = switch (_statusFilter) {
        'active' => !eq.outOfService,
        'maintenance' => eq.outOfService,
        _ => true,
      };

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _toggleStatus(InventoryModel eq) async {
    final nextOos = !eq.outOfService;
    final actionLabel = nextOos ? 'Mark for Maintenance' : 'Mark as Active';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(actionLabel),
        content: Text(
          nextOos
              ? 'Place "${eq.assetTag ?? eq.itemName}" into maintenance / out-of-service mode?'
              : 'Restore "${eq.assetTag ?? eq.itemName}" to active service?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: nextOos ? AppTheme.warningOrange : AppTheme.successGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(nextOos ? 'Set Maintenance' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.setOutOfService(eq.id, nextOos);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipment status updated successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        _loadEquipment();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _showCalibrationDialog(InventoryModel eq) async {
    final techController = TextEditingController();
    final certRefController = TextEditingController();
    DateTime calDate = DateTime.now();
    DateTime nextDueDate = DateTime.now().add(const Duration(days: 180));

    final success = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.verified_outlined, color: AppTheme.accentTeal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Log Calibration: ${eq.assetTag ?? eq.itemName}',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: techController,
                  decoration: const InputDecoration(
                    labelText: 'Technician / Performed By *',
                    hintText: 'e.g. Eng. Sarah Ahmed',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: certRefController,
                  decoration: const InputDecoration(
                    labelText: 'Certificate Reference / Report # *',
                    hintText: 'e.g. CAL-2026-0891',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.receipt_long),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Calibration Date: ${calDate.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('Change Calibration Date'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: calDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setDialogState(() => calDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  'Next Calibration Due: ${nextDueDate.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event, size: 16),
                  label: const Text('Change Next Due Date'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: nextDueDate,
                      firstDate: calDate,
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setDialogState(() => nextDueDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentTeal,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (techController.text.trim().isEmpty ||
                    certRefController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Submit Calibration'),
            ),
          ],
        ),
      ),
    );

    if (success == true) {
      try {
        final payload = {
          'calibrated_at': calDate.toIso8601String().split('T')[0],
          'performed_by': techController.text.trim(),
          'certificate_ref': certRefController.text.trim(),
          'next_calibration_due': nextDueDate.toIso8601String().split('T')[0],
        };
        await _service.logCalibration(eq.id, payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Calibration logged & schedule updated'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
          _loadEquipment();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to log calibration: $e'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  void _showEquipmentDetails(InventoryModel eq) {
    final isOos = eq.outOfService;
    final calDue = eq.nextCalibrationDue != null
        ? eq.nextCalibrationDue!.toLocal().toString().split(' ')[0]
        : 'Not scheduled';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      eq.assetTag ?? eq.itemName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOos
                          ? AppTheme.errorRed.withValues(alpha: 0.12)
                          : AppTheme.successGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOos ? 'MAINTENANCE' : 'ACTIVE',
                      style: TextStyle(
                        color: isOos ? AppTheme.errorRed : AppTheme.successGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _detailRow('Item / Name', eq.itemName),
              _detailRow('Machine Type', eq.machineType ?? 'Commercial Laundromat Asset'),
              _detailRow('SKU', eq.sku),
              _detailRow('Quantity / Units', '${eq.quantity}'),
              _detailRow('Next Calibration Due', calDue),
              _detailRow('System ID', '#${eq.id} (${eq.uuid.substring(0, 8)}...)'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        isOos ? Icons.check_circle_outline : Icons.build_circle_outlined,
                        color: isOos ? AppTheme.successGreen : AppTheme.warningOrange,
                      ),
                      label: Text(
                        isOos ? 'Activate' : 'Maintenance',
                        style: TextStyle(
                          color: isOos ? AppTheme.successGreen : AppTheme.warningOrange,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _toggleStatus(eq);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentTeal,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.verified, size: 18),
                      label: const Text('Calibrate'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showCalibrationDialog(eq);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filtered = _filteredEquipment;

    final activeCount = _equipmentList.where((e) => !e.outOfService).length;
    final maintenanceCount = _equipmentList.where((e) => e.outOfService).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('equipment_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadEquipment,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Metric Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search asset tag, machine type, or item...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _filterChip(
                      label: 'All (${_equipmentList.length})',
                      value: 'all',
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'Active ($activeCount)',
                      value: 'active',
                      badgeColor: AppTheme.successGreen,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'Maintenance ($maintenanceCount)',
                      value: 'maintenance',
                      badgeColor: AppTheme.errorRed,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.precision_manufacturing_outlined,
                              size: 48,
                              color: AppTheme.secondaryGrey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _equipmentList.isEmpty
                                  ? l10n.t('reports_empty')
                                  : 'No equipment matches current filter',
                              style: const TextStyle(color: AppTheme.secondaryGrey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEquipment,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final eq = filtered[index];
                            final outOfService = eq.outOfService;
                            final calDate = eq.nextCalibrationDue != null
                                ? eq.nextCalibrationDue!.toLocal().toString().split(' ')[0]
                                : 'Pending';

                            final isOverdue = eq.nextCalibrationDue != null &&
                                eq.nextCalibrationDue!.isBefore(DateTime.now());

                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: outOfService
                                      ? AppTheme.errorRed.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _showEquipmentDetails(eq),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: outOfService
                                            ? AppTheme.errorRed.withValues(alpha: 0.15)
                                            : AppTheme.accentTeal.withValues(alpha: 0.15),
                                        child: Icon(
                                          outOfService ? Icons.build : Icons.precision_manufacturing,
                                          color: outOfService ? AppTheme.errorRed : AppTheme.accentTeal,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    eq.assetTag ?? 'Asset #${eq.id}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${eq.itemName} • ${eq.machineType ?? 'Machine'}',
                                              style: const TextStyle(
                                                color: AppTheme.secondaryGrey,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.event_outlined,
                                                  size: 14,
                                                  color: isOverdue ? AppTheme.errorRed : AppTheme.secondaryGrey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${l10n.t('equipment_calibration_due')}: $calDate',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: isOverdue ? AppTheme.errorRed : null,
                                                  ),
                                                ),
                                                if (isOverdue) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.errorRed.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Text(
                                                      'OVERDUE',
                                                      style: TextStyle(
                                                        color: AppTheme.errorRed,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: outOfService
                                                  ? AppTheme.errorRed.withValues(alpha: 0.12)
                                                  : AppTheme.successGreen.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              outOfService ? 'MAINTENANCE' : 'ACTIVE',
                                              style: TextStyle(
                                                color: outOfService ? AppTheme.errorRed : AppTheme.successGreen,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert, size: 20),
                                            onSelected: (action) {
                                              if (action == 'calibrate') {
                                                _showCalibrationDialog(eq);
                                              } else if (action == 'status') {
                                                _toggleStatus(eq);
                                              } else if (action == 'details') {
                                                _showEquipmentDetails(eq);
                                              }
                                            },
                                            itemBuilder: (ctx) => [
                                              const PopupMenuItem(
                                                value: 'details',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.info_outline, size: 18),
                                                    SizedBox(width: 8),
                                                    Text('View Details'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'calibrate',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.verified, size: 18, color: AppTheme.accentTeal),
                                                    SizedBox(width: 8),
                                                    Text('Log Calibration'),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'status',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      outOfService ? Icons.check_circle : Icons.build,
                                                      size: 18,
                                                      color: outOfService ? AppTheme.successGreen : AppTheme.warningOrange,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(outOfService ? 'Mark Active' : 'Mark Maintenance'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required String value,
    Color? badgeColor,
  }) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: (badgeColor ?? AppTheme.primaryNavy).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? (badgeColor ?? AppTheme.primaryNavy) : AppTheme.secondaryGrey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _statusFilter = value);
      },
    );
  }
}
