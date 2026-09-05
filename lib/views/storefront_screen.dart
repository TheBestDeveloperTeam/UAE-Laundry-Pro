import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/storefront_service.dart';

class StorefrontScreen extends StatefulWidget {
  const StorefrontScreen({super.key, this.storefrontService});
  final StorefrontService? storefrontService;

  @override
  State<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends State<StorefrontScreen> {
  late final StorefrontService _service;
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = widget.storefrontService ?? StorefrontService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _orders = await _service.listOrders();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _convert(int id) async {
    await _service.convert(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('storefront'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(child: Text(l10n.t('reports_empty')))
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (_, i) {
                    final o = _orders[i];
                    return ListTile(
                      title: Text(o['customer_name']?.toString() ?? ''),
                      subtitle: Text('${o['customer_phone']} • ${o['status']}'),
                      trailing: o['status'] == 'pending'
                          ? TextButton(onPressed: () => _convert(int.parse(o['id'].toString())), child: Text(l10n.t('convert')))
                          : null,
                    );
                  },
                ),
    );
  }
}
