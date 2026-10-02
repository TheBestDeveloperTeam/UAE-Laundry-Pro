import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/theme.dart';
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
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addChannel() async {
    final l10n = context.l10n;
    String channelType = 'whatsapp';
    String provider = 'twilio';
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.campaign_outlined, color: AppTheme.primaryNavy),
              const SizedBox(width: 8),
              Text(l10n.t('channel_add')),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: l10n.t('channel_type')),
                  initialValue: channelType,
                  items: const [
                    DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp Business API')),
                    DropdownMenuItem(value: 'sms', child: Text('Transactional SMS')),
                    DropdownMenuItem(value: 'email', child: Text('Transactional Email')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => channelType = val);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: l10n.t('channel_provider')),
                  initialValue: provider,
                  items: const [
                    DropdownMenuItem(value: 'twilio', child: Text('Twilio SMS / WhatsApp')),
                    DropdownMenuItem(value: 'infobip', child: Text('Infobip MENA Gateway')),
                    DropdownMenuItem(value: 'stub', child: Text('Internal Stub (Diagnostic)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => provider = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.t('pos_close'))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryNavy),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.t('save')),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    setState(() => _loading = true);
    try {
      await _service.create({
        'channel_type': channelType,
        'provider': provider,
        'is_active': 1,
      });
    } catch (_) {}
    await _load();
  }

  Future<void> _sendTestMessage(int channelId, String channelType) async {
    final l10n = context.l10n;
    final recipientController = TextEditingController(text: '+97150');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.send_outlined, color: AppTheme.primaryNavy),
            const SizedBox(width: 8),
            Text(l10n.t('channel_test')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Channel: ${channelType.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: recipientController,
              decoration: InputDecoration(
                labelText: l10n.t('recipient_phone'),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.t('pos_close'))),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentGreen),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send, size: 16, color: AppTheme.primaryNavy),
            label: Text(
              l10n.t('send'),
              style: const TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || recipientController.text.trim().isEmpty) return;

    setState(() => _loading = true);
    try {
      await _service.sendTest(channelId, recipientController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.t('channel_test_sent')),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('notification_channels')),
        actions: [
          IconButton(
            tooltip: l10n.t('refresh'),
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('No channels configured yet.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final c = _items[i];
                    final channelId = c['id'] as int? ?? (i + 1);
                    final type = (c['channel_type'] ?? 'sms').toString().toLowerCase();
                    final provider = (c['provider'] ?? 'stub').toString();
                    final isActive = (c['is_active'] ?? 0) == 1;

                    IconData icon;
                    Color color;
                    if (type == 'whatsapp') {
                      icon = Icons.chat;
                      color = AppTheme.successGreen;
                    } else if (type == 'email') {
                      icon = Icons.email_outlined;
                      color = AppTheme.infoBlue;
                    } else {
                      icon = Icons.sms_outlined;
                      color = AppTheme.accentCyan;
                    }

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type.toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryNavy),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Provider: $provider', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.primaryNavy),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              onPressed: () => _sendTestMessage(channelId, type),
                              icon: const Icon(Icons.send, size: 14, color: AppTheme.primaryNavy),
                              label: Text(l10n.t('channel_test'), style: const TextStyle(fontSize: 12, color: AppTheme.primaryNavy)),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: isActive,
                              activeThumbColor: AppTheme.accentGreen,
                              onChanged: (_) {},
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        onPressed: _addChannel,
        icon: const Icon(Icons.add),
        label: Text(l10n.t('channel_add')),
      ),
    );
  }
}
