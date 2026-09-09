import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/api_client.dart';

class RoleEditorScreen extends StatefulWidget {
  const RoleEditorScreen({super.key});

  @override
  State<RoleEditorScreen> createState() => _RoleEditorScreenState();
}

class _RoleEditorScreenState extends State<RoleEditorScreen> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
  List<dynamic> _roles = [];

  final List<String> _availablePermissions = [
    '*',
    'system.settings',
    'system.config.paths',
    'license.manage',
    'backup.run',
    'backup.restore',
    'sales.create',
    'sales.edit_draft',
    'sales.override_rate',
    'sales.discount_line',
    'sales.discount_order',
    'sales.cancel',
    'sales.reprint',
    'sales.receive_payment',
    'sales.void',
    'sales.memo.credit',
    'sales.memo.debit',
    'catalog.view',
    'catalog.create',
    'catalog.edit',
    'catalog.delete',
    'catalog.pricing',
    'customer.view',
    'customer.create',
    'customer.edit',
    'customer.merge',
    'customer.delete',
    'vendor.view',
    'vendor.create',
    'vendor.edit',
    'inventory.view',
    'inventory.adjust',
    'inventory.reconcile',
    'inventory.transfer',
    'production.status_update',
    'production.qc',
    'production.rework',
    'delivery.dispatch',
    'delivery.complete',
    'delivery.reassign',
    'purchase.create',
    'purchase.receive',
    'purchase.approve',
    'hr.employee.view',
    'hr.attendance.record',
    'hr.leave.approve',
    'hr.payroll.run',
    'hr.payroll.view',
    'hr.advance.approve',
    'expense.create',
    'expense.approve',
    'expense.view',
    'reports.sales',
    'reports.inventory',
    'reports.hr',
    'reports.financial',
    'reports.export',
    'hardware.configure',
    'hardware.test',
  ];

  @override
  void initState() {
    super.initState();
    _fetchRoles();
  }

  Future<void> _fetchRoles() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/roles');
      if (mounted) {
        setState(() {
          _roles = res['data']?['roles'] ?? [];
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load roles')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateRole(int id, String name, List<dynamic> permissions) async {
    try {
      await _api.put('/roles/$id', body: {'name': name, 'permissions': permissions});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role updated successfully')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update role')),
        );
      }
    }
  }

  void _showRoleDialog(Map<dynamic, dynamic>? role) {
    final isNew = role == null;
    final nameController = TextEditingController(text: role?['name'] ?? '');
    final List<String> currentPermissions =
        role != null ? List<String>.from(role['permissions']) : [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isNew ? 'New Role' : 'Edit Role'),
              content: SizedBox(
                width: 600,
                height: 500,
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Role Name'),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _availablePermissions.length,
                        itemBuilder: (context, index) {
                          final perm = _availablePermissions[index];
                          return CheckboxListTile(
                            title: Text(perm),
                            value: currentPermissions.contains(perm),
                            onChanged: (val) {
                              setStateDialog(() {
                                if (val == true) {
                                  currentPermissions.add(perm);
                                } else {
                                  currentPermissions.remove(perm);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (isNew) {
                      try {
                        await _api.post('/roles', body: {
                          'name': nameController.text,
                          'permissions': currentPermissions,
                        });
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        _fetchRoles();
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to create role')),
                        );
                      }
                    } else {
                      await _updateRole(role['id'], nameController.text, currentPermissions);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _fetchRoles();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('roles_permissions')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showRoleDialog(null),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _roles.length,
              itemBuilder: (context, index) {
                final role = _roles[index];
                return Card(
                  child: ListTile(
                    title: Text(role['name'].toString().toUpperCase()),
                    subtitle: Text('${(role['permissions'] as List).length} permissions'),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _showRoleDialog(role),
                  ),
                );
              },
            ),
    );
  }
}
