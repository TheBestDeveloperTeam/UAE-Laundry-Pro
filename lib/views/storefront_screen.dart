import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/theme.dart';
import 'package:laundrypro_uae/services/storefront_service.dart';

class StorefrontScreen extends StatefulWidget {
  const StorefrontScreen({super.key, this.storefrontService});
  final StorefrontService? storefrontService;

  @override
  State<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends State<StorefrontScreen> {
  late final StorefrontService _service;
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _service = widget.storefrontService ?? StorefrontService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final statusParam = _selectedFilter == 'all' ? null : _selectedFilter;
      _orders = await _service.listOrders(status: statusParam);
    } catch (e, stack) {
      AppLogger.error('Failed to load storefront orders', tag: 'StorefrontScreen', error: e, stackTrace: stack);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _convert(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.t('convert')),
        content: Text(ctx.l10n.t('storefront_convert_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.t('convert')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await _service.convert(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.t('storefront_convert_success')),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e, stack) {
      AppLogger.error('Failed to convert storefront order $id', tag: 'StorefrontScreen', error: e, stackTrace: stack);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final pendingCount = _orders.where((o) => o['status'] == 'pending').length;
    final convertedCount = _orders.where((o) => o['status'] == 'converted').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('storefront')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          // KPI metrics
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('storefront_filter_pending'),
                          style: const TextStyle(fontSize: 12, color: AppTheme.secondaryGrey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$pendingCount',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.warningOrange),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('storefront_filter_converted'),
                          style: const TextStyle(fontSize: 12, color: AppTheme.secondaryGrey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$convertedCount',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentTeal),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.t('storefront_filter_all')),
                  selected: _selectedFilter == 'all',
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedFilter = 'all');
                      _load();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.t('storefront_filter_pending')),
                  selected: _selectedFilter == 'pending',
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedFilter = 'pending');
                      _load();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.t('storefront_filter_converted')),
                  selected: _selectedFilter == 'converted',
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedFilter = 'converted');
                      _load();
                    }
                  },
                ),
              ],
            ),
          ),

          // Orders list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? Center(child: Text(l10n.t('reports_empty'), style: const TextStyle(color: AppTheme.secondaryGrey)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final o = _orders[i];
                            final id = o['id'] is int ? o['id'] as int : int.tryParse('${o['id']}') ?? 0;
                            final isPending = o['status'] == 'pending';
                            final total = double.tryParse('${o['total']}') ?? 0.0;

                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isPending
                                          ? AppTheme.warningOrange.withValues(alpha: 0.15)
                                          : AppTheme.accentTeal.withValues(alpha: 0.15),
                                      child: Icon(
                                        isPending ? Icons.pending_actions : Icons.check_circle_outline,
                                        color: isPending ? AppTheme.warningOrange : AppTheme.accentTeal,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            o['customer_name']?.toString() ?? 'Online Customer',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${o['customer_phone'] ?? 'N/A'} • Ref: #${o['order_number'] ?? id}',
                                            style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 13),
                                          ),
                                          if (total > 0)
                                            Text(
                                              '${total.toStringAsFixed(2)} AED',
                                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryNavy),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isPending)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryNavy,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: const Icon(Icons.arrow_forward, size: 16),
                                        label: Text(l10n.t('convert')),
                                        onPressed: () => _convert(id),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentTeal.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          l10n.t('storefront_filter_converted'),
                                          style: const TextStyle(
                                            color: AppTheme.accentTeal,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
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
}
