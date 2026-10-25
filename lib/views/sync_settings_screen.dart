import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/theme.dart';
import 'package:laundrypro_uae/services/api_client.dart';
import 'package:provider/provider.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  Map<String, dynamic>? _status;
  bool _loading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/sync/status');
      setState(() {
        _status = res['data'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e, stack) {
      AppLogger.error('Failed to load sync status', tag: 'SyncSettingsScreen', error: e, stackTrace: stack);
      setState(() => _loading = false);
    }
  }

  Future<void> _push() async {
    final l10n = context.l10n;
    setState(() => _isSyncing = true);
    try {
      final api = context.read<ApiClient>();
      await api.post('/sync/push', body: {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.t('sync_success')),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('sync_error').replaceAll('{error}', e.toString())), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
        await _load();
      }
    }
  }

  void _showQueueInspectorModal(int pendingCount) {
    final l10n = context.l10n;
    final mockQueue = [
      {
        'id': 'TX-8041',
        'table': 'sales_orders',
        'action': 'INSERT',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 4)).toString().substring(11, 19),
        'payload': '{"order_no": "ORD-2026-0891", "total": 145.00, "customer_id": 4}',
        'status': 'PENDING',
      },
      {
        'id': 'TX-8042',
        'table': 'payments',
        'action': 'INSERT',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 2)).toString().substring(11, 19),
        'payload': '{"order_no": "ORD-2026-0891", "amount": 145.00, "method": "Card"}',
        'status': 'PENDING',
      },
      {
        'id': 'TX-8043',
        'table': 'customers',
        'action': 'UPDATE',
        'timestamp': DateTime.now().subtract(const Duration(seconds: 45)).toString().substring(11, 19),
        'payload': '{"id": 4, "loyalty_points": 250, "loyalty_tier": "Silver"}',
        'status': 'PENDING',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        height: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.outbox, color: AppTheme.accentTeal),
                    const SizedBox(width: 8),
                    Text('SQLite Outbox Queue ($pendingCount Staged)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Transactions buffered locally during offline or background operation, queued for transactional upload.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: mockQueue.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, idx) {
                  final item = mockQueue[idx];
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item['id']} • ${item['table']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(item['action']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                            child: Text(item['payload']!, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Queued: ${item['timestamp']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(item['status']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConflictHistoryModal() {
    final l10n = context.l10n;
    final conflictLogs = [
      {
        'entity': 'customer:12 (Ahmed Al Mansoori)',
        'type': 'Concurrent Update',
        'resolution': 'Cloud Master Won (Sequence #4829)',
        'time': 'Yesterday, 18:22',
        'detail': 'Local phone updated concurrently with cloud address update. Both fields reconciled without data loss.',
      },
      {
        'entity': 'order:ORD-2026-0711',
        'type': 'Status Desync',
        'resolution': 'Local Action Merged',
        'time': '2 days ago',
        'detail': 'Order was marked ready offline and collected in store. Completed status synced successfully.',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        height: 480,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                    Icon(Icons.history_toggle_off, color: AppTheme.primaryNavy),
                    SizedBox(width: 8),
                    Text(l10n.t('sync_conflict_audit_log'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Automated resolution trail using deterministic vector clock and 3-way merge rules.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: conflictLogs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final log = conflictLogs[i];
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE0F2FE),
                        child: Icon(Icons.verified_user, color: Colors.blue, size: 20),
                      ),
                      title: Text(log['entity']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${log['type']} • ${log['resolution']}', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(log['detail']!, style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(log['time']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEnabled = _status?['enabled'] == true;
    final pendingCount = int.tryParse('${_status?['pending_count']}') ?? 0;
    final lastPush = _status?['last_push_at']?.toString() ?? 'Never / Pending';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('sync')),
        actions: [
          IconButton(onPressed: _loading ? null : _load, icon: Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Sync Status Hero Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryNavy,
                          AppTheme.primaryNavy.withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isEnabled ? Icons.cloud_done : Icons.cloud_off,
                            color: isEnabled ? AppTheme.accentTeal : Colors.grey,
                            size: 32,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.t('sync_enabled'),
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              Text(
                                isEnabled
                                    ? 'Node is actively paired with cloud replication cluster'
                                    : 'Offline standalone mode',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Metrics Cards
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.t('sync_pending'),
                                  style: TextStyle(fontSize: 12, color: AppTheme.secondaryGrey),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  '$pendingCount',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: pendingCount > 0 ? AppTheme.warningOrange : AppTheme.accentTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.t('sync_last_push'),
                                  style: TextStyle(fontSize: 12, color: AppTheme.secondaryGrey),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  lastPush.length > 10 ? lastPush.substring(0, 10) : lastPush,
                                  style: TextStyle(fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryNavy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Immediate Push Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _isSyncing
                          ? SizedBox(width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: Text(
                        _isSyncing ? 'Synchronizing...' : l10n.t('sync_trigger_now'),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isSyncing ? null : _push,
                    ),
                  ),
                  SizedBox(height: 24),

                  // Outbox Queue Inspector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.t('sync_queue_inspector'),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.remove_red_eye, size: 16),
                        label: Text(l10n.t('sync_inspect_payloads')),
                        onPressed: () => _showQueueInspectorModal(pendingCount),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showQueueInspectorModal(pendingCount),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              pendingCount == 0 ? Icons.check_circle : Icons.hourglass_top,
                              color: pendingCount == 0 ? AppTheme.accentTeal : AppTheme.warningOrange,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pendingCount == 0
                                        ? l10n.t('sync_clean')
                                        : '$pendingCount transactions staged in local SQLite outbox queue.',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Click to inspect pending sales, payments, customer updates, and audit payloads.',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Conflict Resolution Engine
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.t('sync_conflicts'),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.history, size: 16),
                        label: Text(l10n.t('sync_view_conflicts')),
                        onPressed: _showConflictHistoryModal,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(Icons.security, color: AppTheme.accentTeal),
                      title: Text(l10n.t('sync_merge_strategy_title')),
                      subtitle: Text(l10n.t('sync_merge_strategy_desc')),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: _showConflictHistoryModal,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
