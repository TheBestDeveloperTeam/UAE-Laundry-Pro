import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/customer_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key, this.customerService});

  final CustomerService? customerService;

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late final CustomerService _customers;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _customers = widget.customerService ?? CustomerService();
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
      _items = await _customers.list(query: _searchController.text.trim());
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _create() async {
    final customersLabel = context.l10n.t('customers');
    final nameLabel = context.l10n.t('name');
    final phoneLabel = context.l10n.t('phone');
    final name = await _promptField(customersLabel, nameLabel);
    if (name == null || name.isEmpty) return;
    if (!mounted) return;
    final phone = await _promptField(phoneLabel, '');
    await _customers.create({'name': name, if (phone != null && phone.isNotEmpty) 'phone': phone});
    await _load();
  }

  Future<String?> _promptField(String title, String label) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: label), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.t('pos_close'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(context.l10n.t('save'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('customers')),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
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
                IconButton(onPressed: _load, icon: const Icon(Icons.search)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final c = _items[i];
                      return ListTile(
                        title: Text(c['name']?.toString() ?? ''),
                        subtitle: Text(c['phone']?.toString() ?? ''),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _create, child: const Icon(Icons.add)),
    );
  }
}
