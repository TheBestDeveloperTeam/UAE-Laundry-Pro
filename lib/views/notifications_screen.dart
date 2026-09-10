import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _svc = NotificationService();
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

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
      if (mounted) setState(() => _items = res);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await _svc.markRead(id);
      await _load();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _svc.markAllRead();
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('notifications')),
        actions: [
          TextButton.icon(
            onPressed: _markAllRead,
            icon: const Icon(Icons.done_all),
            label: Text(l10n.t('mark_all_read')),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(l10n.t('notifications_empty') ?? 'No notifications'))
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = _items[i];
                    final id = int.tryParse(e['id']?.toString() ?? '0') ?? 0;
                    final read = e['is_read'] == 1 || e['is_read'] == true;
                    final dt = DateTime.tryParse(e['created_at']?.toString() ?? '') ?? DateTime.now();

                    return ListTile(
                      tileColor: read ? null : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                      leading: Icon(
                        e['severity'] == 'critical' ? Icons.error : (e['severity'] == 'warning' ? Icons.warning : Icons.info),
                        color: e['severity'] == 'critical' ? Colors.red : (e['severity'] == 'warning' ? Colors.amber : Colors.blue),
                      ),
                      title: Text(e['title'] ?? '', style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.bold)),
                      subtitle: Text('\\n\'),
                      isThreeLine: true,
                      trailing: read
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.check),
                              tooltip: 'Mark as read',
                              onPressed: () => _markRead(id),
                            ),
                    );
                  },
                ),
    );
  }
}
