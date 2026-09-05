import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
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
  List<Map<String, dynamic>> _branchList = [];
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
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _add() async {
    if (_branchList.isEmpty) return;
    await _terminals.create({
      'branch_id': _branchList.first['id'],
      'code': 'T${DateTime.now().millisecond}',
      'name': 'Terminal',
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('terminals'))),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final t = _items[i];
                return ListTile(
                  leading: const Icon(Icons.computer),
                  title: Text(t['name']?.toString() ?? ''),
                  subtitle: Text('${t['code']} — ${t['branch_code'] ?? ''}'),
                );
              },
            ),
    );
  }
}
