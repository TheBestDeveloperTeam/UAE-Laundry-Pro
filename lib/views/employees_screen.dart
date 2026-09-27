import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/models/employee_model.dart';
import 'package:laundrypro_uae/services/employee_service.dart';
import 'package:laundrypro_uae/widgets/app_data_table.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key, this.employeeService});

  final EmployeeService? employeeService;

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  late final EmployeeService _employees;
  final _searchController = TextEditingController();
  List<EmployeeModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _employees = widget.employeeService ?? EmployeeService();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _employees.list(query: _searchController.text.trim());
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _create() async {
    final l10n = context.l10n;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('employee_create')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: l10n.t('name')), autofocus: true),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: l10n.t('phone'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.t('pos_close'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.t('save'))),
        ],
      ),
    );
    if (ok != true || nameController.text.trim().isEmpty) return;
    await _employees.create({
      'full_name': nameController.text.trim(),
      if (phoneController.text.isNotEmpty) 'phone': phoneController.text.trim(),
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('employees')),
        actions: [IconButton(onPressed: _load, icon: Icon(PhosphorPhosphorIcons.circle()()))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(hintText: l10n.t('search'), isDense: true),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                IconButton(onPressed: _load, icon: Icon(PhosphorPhosphorIcons.circle()())),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(child: Text(l10n.t('employees_empty')))
                    : Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        clipBehavior: Clip.antiAlias,
                        child: AppDataTable(
                          columns: const [
                            AppDataTableColumn(label: 'Code', key: 'employee_code'),
                            AppDataTableColumn(label: 'Name', key: 'full_name'),
                            AppDataTableColumn(label: 'Phone', key: 'phone'),
                          ],
                          data: _items.map((e) => e.toJson()).toList(),
                          isLoading: _loading,
                          emptyMessage: l10n.t('employees_empty'),
                          onRowTap: (row) {
                             // Can expand later to edit employee
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _create, child: Icon(PhosphorPhosphorIcons.circle()())),
    );
  }
}
