import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/theme.dart';
import 'package:laundrypro_uae/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _svc = NotificationService();
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await _svc.generateAlerts(); // Generate fresh alerts
      final res = await _svc.list();
      if (mounted) {
        setState(() => _items = res);
        // Check for unread critical alerts and alert operator
        final criticals = res.where((e) => (e['is_read'] != 1 && e['is_read'] != true) && e['severity'] == 'critical').toList();
        if (criticals.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('CRITICAL ALERT: ${criticals.first['title'] ?? 'System alert requiring immediate attention'}')),
                ],
              ),
              backgroundColor: AppTheme.errorRed,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e, stack) {
      AppLogger.error('Failed to load notifications or alerts', tag: 'NotificationsScreen', error: e, stackTrace: stack);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await _svc.markRead(id);
      await _load();
    } catch (e, stack) {
      AppLogger.error('Failed to mark notification $id as read', tag: 'NotificationsScreen', error: e, stackTrace: stack);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _svc.markAllRead();
      await _load();
    } catch (e, stack) {
      AppLogger.error('Failed to mark all notifications as read', tag: 'NotificationsScreen', error: e, stackTrace: stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final unreadCount = _items.where((e) => e['is_read'] != 1 && e['is_read'] != true).length;
    final filtered = _activeFilter == 'unread'
        ? _items.where((e) => e['is_read'] != 1 && e['is_read'] != true).toList()
        : _items;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('notifications')),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: Text(l10n.t('notifications_mark_all')),
            ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips & Counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('All (${_items.length})'),
                  selected: _activeFilter == 'all',
                  onSelected: (val) {
                    if (val) setState(() => _activeFilter = 'all');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('${l10n.t('notifications_unread_only')} ($unreadCount)'),
                  selected: _activeFilter == 'unread',
                  onSelected: (val) {
                    if (val) setState(() => _activeFilter = 'unread');
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Notification List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_none, size: 64, color: AppTheme.secondaryGrey),
                            const SizedBox(height: 12),
                            Text(
                              l10n.t('notifications_empty'),
                              style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final e = filtered[i];
                            final id = int.tryParse(e['id']?.toString() ?? '0') ?? 0;
                            final read = e['is_read'] == 1 || e['is_read'] == true;
                            final dt = DateTime.tryParse(e['created_at']?.toString() ?? '') ?? DateTime.now();
                            final isCritical = e['severity'] == 'critical';
                            final isWarning = e['severity'] == 'warning';

                            final color = isCritical
                                ? AppTheme.errorRed
                                : (isWarning ? AppTheme.warningOrange : AppTheme.accentTeal);

                            return Card(
                              elevation: read ? 1 : 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: read
                                    ? BorderSide(color: Colors.grey.shade200)
                                    : BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(14),
                                leading: CircleAvatar(
                                  backgroundColor: color.withValues(alpha: 0.15),
                                  child: Icon(
                                    isCritical
                                        ? Icons.error_outline
                                        : (isWarning ? Icons.warning_amber : Icons.notifications_active),
                                    color: color,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        e['title'] ?? 'System Notification',
                                        style: TextStyle(
                                          fontWeight: read ? FontWeight.w600 : FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (!read)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Text(
                                      e['message'] ?? '',
                                      style: TextStyle(
                                        color: read ? AppTheme.secondaryGrey : Colors.black87,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      dt.toLocal().toString().split('.')[0],
                                      style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 11),
                                    ),
                                  ],
                                ),
                                trailing: read
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.check_circle_outline, color: AppTheme.primaryNavy),
                                        tooltip: 'Mark as read',
                                        onPressed: () => _markRead(id),
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
