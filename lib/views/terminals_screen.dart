import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/logger.dart';
import 'package:laundrypro_uae/core/safe_parser.dart';
import 'package:laundrypro_uae/core/theme.dart';
import 'package:laundrypro_uae/models/branch_model.dart';
import 'package:laundrypro_uae/services/branch_service.dart';
import 'package:laundrypro_uae/services/terminal_service.dart';

class TerminalsScreen extends StatefulWidget {
  const TerminalsScreen({super.key, this.terminalService, this.branchService});
  final TerminalService? terminalService;
  final BranchService? branchService;

  @override
  State<TerminalsScreen> createState() => _TerminalsScreenState();
}

class _TerminalsScreenState extends State<TerminalsScreen> {
  late final TerminalService _terminals;
  late final BranchService _branches;
  List<Map<String, dynamic>> _items = [];
  List<BranchModel> _branchList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _terminals = widget.terminalService ?? TerminalService();
    _branches = widget.branchService ?? BranchService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _terminals.list();
      _branchList = await _branches.list();
    } catch (e, stack) {
      AppLogger.error('Failed to load terminals or branches', tag: 'TerminalsScreen', error: e, stackTrace: stack);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _showAddTerminalDialog([Map<String, dynamic>? existing]) {
    if (_branchList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a branch first before pairing terminals')),
      );
      return;
    }

    final isNew = existing == null;
    int selectedBranchId = existing != null
        ? SafeParser.parseInt(existing['branch_id'], _branchList.first.id)
        : _branchList.first.id;
    final codeCtrl = TextEditingController(text: existing?['code']?.toString() ?? 'POS-0${_items.length + 1}');
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? 'Counter Workstation ${_items.length + 1}');
    final ipCtrl = TextEditingController(text: existing?['ip_address']?.toString() ?? '192.168.1.1${_items.length + 10}');
    final macCtrl = TextEditingController(text: existing?['mac_address']?.toString() ?? 'B8:27:EB:5A:24:0${_items.length + 1}');
    final tokenCtrl = TextEditingController(text: existing?['auth_token']?.toString() ?? 'LP-SEC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dlgCtx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isNew ? Icons.add_to_queue : Icons.settings_ethernet, color: AppTheme.primaryNavy),
              const SizedBox(width: 8),
              Text(isNew ? ctx.l10n.t('terminal_add') : 'Configure Terminal Hardware'),
            ],
          ),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedBranchId,
                    decoration: InputDecoration(
                      labelText: ctx.l10n.t('branches'),
                      border: const OutlineInputBorder(),
                    ),
                    items: _branchList.map((b) {
                      return DropdownMenuItem<int>(
                        value: b.id,
                        child: Text('${b.name} (${b.code})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedBranchId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: codeCtrl,
                          decoration: InputDecoration(
                            labelText: ctx.l10n.t('terminal_code'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: ctx.l10n.t('terminal_name'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ipCtrl,
                          decoration: const InputDecoration(
                            labelText: 'LAN Binding IP Address',
                            hintText: '192.168.1.100',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.wifi),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: macCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Hardware MAC Address',
                            hintText: 'XX:XX:XX:XX:XX:XX',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.perm_device_information),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tokenCtrl,
                    decoration: InputDecoration(
                      labelText: 'Hardware Security Auth Token',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.vpn_key),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Regenerate Token',
                        onPressed: () {
                          setModalState(() {
                            tokenCtrl.text = 'LP-SEC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (codeCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                setState(() => _loading = true);
                try {
                  await _terminals.create({
                    'branch_id': selectedBranchId,
                    'code': codeCtrl.text.trim(),
                    'name': nameCtrl.text.trim(),
                    'ip_address': ipCtrl.text.trim(),
                    'mac_address': macCtrl.text.trim(),
                    'auth_token': tokenCtrl.text.trim(),
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.t('terminal_paired')),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  }
                } catch (e, stack) {
                  AppLogger.error('Failed to pair terminal', tag: 'TerminalsScreen', error: e, stackTrace: stack);
                }
                await _load();
              },
              child: Text(ctx.l10n.t('save')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('terminals')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_to_queue),
        label: Text(l10n.t('terminal_add')),
        onPressed: _showAddTerminalDialog,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text(
                    l10n.t('reports_empty'),
                    style: const TextStyle(color: AppTheme.secondaryGrey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final t = _items[i];
                      final ip = t['ip_address']?.toString() ?? '192.168.1.10${i + 1}';
                      final mac = t['mac_address']?.toString() ?? 'B8:27:EB:5A:24:0${i + 1}';
                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryNavy.withValues(alpha: 0.12),
                            child: const Icon(Icons.point_of_sale, color: AppTheme.primaryNavy),
                          ),
                          title: Text(t['name']?.toString() ?? 'Terminal POS', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ID: ${t['code']} • Branch: ${t['branch_code'] ?? 'MAIN'}',
                                style: const TextStyle(color: AppTheme.secondaryGrey),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.wifi, size: 14, color: AppTheme.accentTeal),
                                  const SizedBox(width: 4),
                                  Text(ip, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.fingerprint, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(mac, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentTeal.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'LAN BOUND',
                                  style: TextStyle(
                                    color: AppTheme.accentTeal,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.tune, color: AppTheme.primaryNavy),
                                onPressed: () => _showAddTerminalDialog(t),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
