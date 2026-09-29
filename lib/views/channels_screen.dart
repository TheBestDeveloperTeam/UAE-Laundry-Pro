import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/channel_service.dart';

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key, this.channelService});
  final ChannelService? channelService;

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  late final ChannelService _service;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = widget.channelService ?? ChannelService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _service.list();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _addSms() async {
    await _service.create({'channel_type': 'sms', 'provider': 'stub'});
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('notification_channels'))),
      floatingActionButton: FloatingActionButton(onPressed: _addSms, child: const Icon(Icons.sms)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final c = _items[i];
                return ListTile(
                  leading: Icon(c['channel_type'] == 'whatsapp' ? Icons.chat : Icons.sms),
                  title: Text('${c['channel_type']} (${c['provider']})'),
                  trailing: Switch(value: (c['is_active'] ?? 0) == 1, onChanged: null),
                );
              },
            ),
    );
  }
}
