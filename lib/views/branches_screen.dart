import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/theme.dart';
import 'package:laundrypro_uae/models/branch_model.dart';
import 'package:laundrypro_uae/services/branch_service.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key, this.branchService});
  final BranchService? branchService;

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  late final BranchService _service;
  List<BranchModel> _items = [];
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
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _showAddBranchDialog([BranchModel? existing]) {
    final isNew = existing == null;
    final codeCtrl = TextEditingController(text: existing?.code ?? 'BR0${_items.length + 1}');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final locCtrl = TextEditingController(text: existing?.location ?? '');
    final phoneCtrl = TextEditingController(text: existing?.contactNumber ?? '');
    final hoursCtrl = TextEditingController(text: existing?.operatingHours ?? '08:00 - 22:00');
    final managerCtrl = TextEditingController(text: existing?.managerName ?? '');
    String selectedEmirate = existing?.emirate ?? 'Dubai';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dlgCtx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isNew ? Icons.add_business : Icons.store, color: AppTheme.primaryNavy),
              const SizedBox(width: 8),
              Text(isNew ? ctx.l10n.t('branch_add') : 'Configure Branch'),
            ],
          ),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: codeCtrl,
                          decoration: InputDecoration(
                            labelText: ctx.l10n.t('branch_code'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedEmirate,
                          decoration: const InputDecoration(labelText: 'Emirate', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'Abu Dhabi', child: Text('Abu Dhabi')),
                            DropdownMenuItem(value: 'Dubai', child: Text('Dubai')),
                            DropdownMenuItem(value: 'Sharjah', child: Text('Sharjah')),
                            DropdownMenuItem(value: 'Ajman', child: Text('Ajman')),
                            DropdownMenuItem(value: 'Ras Al Khaimah', child: Text('Ras Al Khaimah')),
                            DropdownMenuItem(value: 'Fujairah', child: Text('Fujairah')),
                            DropdownMenuItem(value: 'Umm Al Quwain', child: Text('Umm Al Quwain')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDlgState(() => selectedEmirate = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: ctx.l10n.t('branch_name'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locCtrl,
                    decoration: InputDecoration(
                      labelText: ctx.l10n.t('branch_location'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Branch Phone',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: managerCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Branch Manager',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hoursCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Operating Schedule / Hours',
                      hintText: 'e.g. 08:00 - 22:00 (Sat-Thu), 14:00 - 22:00 (Fri)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
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
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                setState(() => _loading = true);
                try {
                  await _service.create({
                    'code': codeCtrl.text.trim(),
                    'name': nameCtrl.text.trim(),
                    'location': locCtrl.text.trim(),
                    'contact_number': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    'operating_hours': hoursCtrl.text.trim(),
                    'manager_name': managerCtrl.text.trim().isEmpty ? null : managerCtrl.text.trim(),
                    'emirate': selectedEmirate,
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.t('branch_created')),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  }
                } catch (_) {}
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
        title: Text(l10n.t('branches')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business),
        label: Text(l10n.t('branch_add')),
        onPressed: () => _showAddBranchDialog(),
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
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final b = _items[i];
                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.accentTeal.withValues(alpha: 0.15),
                                    child: const Icon(Icons.store, color: AppTheme.accentTeal),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text(
                                          'Code: ${b.code} • ${b.emirate} • ${b.location.isEmpty ? 'Main Outlet' : b.location}',
                                          style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successGreen.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        color: AppTheme.successGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.schedule, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            b.operatingHours,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (b.managerName != null && b.managerName!.isNotEmpty)
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.person_pin, size: 16, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Mgr: ${b.managerName}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (b.contactNumber != null && b.contactNumber!.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(b.contactNumber!, style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                ],
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
