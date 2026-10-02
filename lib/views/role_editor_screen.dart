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

  static final Map<String, List<String>> _permissionCategories = {
    'System & Admin': [
      '*',
      'system.settings',
      'system.config.paths',
      'license.manage',
      'backup.run',
      'backup.restore',
      'hardware.configure',
      'hardware.test',
    ],
    'Point of Sale (POS) & Billing': [
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
    ],
    'Catalog & Customers': [
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
    ],
    'Inventory & Operations': [
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
    ],
    'HR & Payroll': [
      'hr.employee.view',
      'hr.attendance.record',
      'hr.leave.approve',
      'hr.payroll.run',
      'hr.payroll.view',
      'hr.advance.approve',
      'expense.create',
      'expense.approve',
      'expense.view',
    ],
    'Financial & Reports': [
      'reports.sales',
      'reports.inventory',
      'reports.hr',
      'reports.financial',
      'reports.export',
    ],
  };

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
              title: Row(
                children: [
                  Icon(isNew ? Icons.add_moderator : Icons.security, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(isNew ? 'New Role Configuration' : 'Edit Role Permissions'),
                ],
              ),
              content: SizedBox(
                width: 720,
                height: 560,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Role Title (e.g. Branch Supervisor)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${currentPermissions.length} permissions granted',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.select_all, size: 16),
                              label: const Text('Grant All (*)'),
                              onPressed: () {
                                setStateDialog(() {
                                  if (!currentPermissions.contains('*')) {
                                    currentPermissions.add('*');
                                  }
                                  for (final cat in _permissionCategories.values) {
                                    for (final p in cat) {
                                      if (!currentPermissions.contains(p)) currentPermissions.add(p);
                                    }
                                  }
                                });
                              },
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.clear_all, size: 16),
                              label: const Text('Clear All'),
                              onPressed: () {
                                setStateDialog(() {
                                  currentPermissions.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        children: _permissionCategories.entries.map((catEntry) {
                          final categoryName = catEntry.key;
                          final permissions = catEntry.value;
                          final grantedCount = permissions.where((p) => currentPermissions.contains(p)).length;
                          final allInCatGranted = grantedCount == permissions.length;

                          return ExpansionTile(
                            initiallyExpanded: true,
                            leading: Icon(
                              allInCatGranted ? Icons.check_circle : (grantedCount > 0 ? Icons.indeterminate_check_box : Icons.radio_button_unchecked),
                              color: allInCatGranted ? Colors.teal : (grantedCount > 0 ? Colors.orange : Colors.grey),
                            ),
                            title: Text(
                              categoryName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text('$grantedCount of ${permissions.length} active'),
                            trailing: TextButton(
                              child: Text(allInCatGranted ? 'Revoke Group' : 'Grant Group'),
                              onPressed: () {
                                setStateDialog(() {
                                  if (allInCatGranted) {
                                    for (final p in permissions) {
                                      currentPermissions.remove(p);
                                    }
                                  } else {
                                    for (final p in permissions) {
                                      if (!currentPermissions.contains(p)) currentPermissions.add(p);
                                    }
                                  }
                                });
                              },
                            ),
                            children: permissions.map((perm) {
                              final isPermGranted = currentPermissions.contains(perm);
                              return CheckboxListTile(
                                dense: true,
                                title: Text(
                                  perm,
                                  style: TextStyle(
                                    fontWeight: perm == '*' ? FontWeight.bold : FontWeight.normal,
                                    color: perm == '*' ? Colors.red[800] : null,
                                  ),
                                ),
                                subtitle: perm == '*' ? const Text('Full Wildcard Access across the system') : null,
                                value: isPermGranted,
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
                            }).toList(),
                          );
                        }).toList(),
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
                  child: Text(context.l10n.t('save')),
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
