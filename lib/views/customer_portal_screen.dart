import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/services/customer_portal_service.dart';

class CustomerPortalScreen extends StatefulWidget {
  const CustomerPortalScreen({super.key, this.portalService});
  final CustomerPortalService? portalService;

  @override
  State<CustomerPortalScreen> createState() => _CustomerPortalScreenState();
}

class _CustomerPortalScreenState extends State<CustomerPortalScreen> {
  late final CustomerPortalService _service;
  final _tokenController = TextEditingController();
  Map<String, dynamic>? _order;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _service = widget.portalService ?? CustomerPortalService();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    setState(() {
      _loading = true;
      _order = null;
    });
    try {
      _order = await _service.orderStatus(_tokenController.text.trim());
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('customer_portal'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(labelText: l10n.t('portal_token')),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loading ? null : _lookup, child: Text(l10n.t('lookup'))),
            const SizedBox(height: 24),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_order != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${l10n.t('order_no')}: ${_order!['order_no']}'),
                      Text('${l10n.t('status')}: ${_order!['status']}'),
                      Text('${l10n.t('total')}: ${_order!['grand_total']}'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
