import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/branch_service.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key, this.branchService});
  final BranchService? branchService;

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  late final BranchService _service;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = widget.branchService ?? BranchService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _service.list();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _add() async {
    await _service.create({'code': 'BR${DateTime.now().millisecond}', 'name': 'New Branch'});
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('branches'))),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(l10n.t('reports_empty')))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final b = _items[i];
                    return ListTile(
                      leading: const Icon(Icons.store),
                      title: Text(b['name']?.toString() ?? ''),
                      subtitle: Text(b['code']?.toString() ?? ''),
                    );
                  },
                ),
    );
  }
}
