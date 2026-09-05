import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.notificationService});

  final NotificationService? notificationService;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationService _notifications;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _notifications = widget.notificationService ?? NotificationService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _notifications.list(unreadOnly: _unreadOnly);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    final id = int.tryParse(item['id']?.toString() ?? '');
    if (id == null) return;
    await _notifications.markRead(id);
    await _load();
  }

  Future<void> _markAllRead() async {
    await _notifications.markAllRead();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('notifications')),
        actions: [
          IconButton(
            icon: Icon(_unreadOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            tooltip: l10n.t('notifications_unread_only'),
            onPressed: () {
              _unreadOnly = !_unreadOnly;
              _load();
            },
          ),
          IconButton(onPressed: _markAllRead, icon: const Icon(Icons.done_all), tooltip: l10n.t('notifications_mark_all')),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(l10n.t('notifications_empty')))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final n = _items[i];
                    final isRead = n['is_read'] == true || n['is_read'] == 1;
                    return ListTile(
                      leading: Icon(isRead ? Icons.notifications_none : Icons.notifications_active, color: isRead ? null : Theme.of(context).colorScheme.primary),
                      title: Text(n['title']?.toString() ?? ''),
                      subtitle: Text(n['message']?.toString() ?? ''),
                      onTap: () => _markRead(n),
                    );
                  },
                ),
    );
  }
}
