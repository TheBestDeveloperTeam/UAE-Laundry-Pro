import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/receipt_model.dart';
import 'package:laundrypro_uae/core/receipt_renderer.dart';
import 'package:laundrypro_uae/core/theme.dart';
import 'package:laundrypro_uae/services/customer_portal_service.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class CustomerPortalScreen extends StatefulWidget {
  const CustomerPortalScreen({super.key, this.portalService});
  final CustomerPortalService? portalService;

  @override
  State<CustomerPortalScreen> createState() => _CustomerPortalScreenState();
}

class _CustomerPortalScreenState extends State<CustomerPortalScreen> with SingleTickerProviderStateMixin {
  late final CustomerPortalService _service;
  late final TabController _tabController;

  final _tokenController = TextEditingController();
  Map<String, dynamic>? _order;
  bool _loading = false;
  String? _errorMessage;

  final _b2bCompanyController = TextEditingController(text: 'Grand Hyatt Dubai');
  final _b2bTrnController = TextEditingController(text: '100492817200003');
  final _b2bAddressController = TextEditingController(text: 'Oud Metha Rd, Dubai Healthcare City, Dubai');
  final _b2bNotesController = TextEditingController(text: 'Daily linen & banquet uniforms exchange');
  int _b2bEstimatedGarments = 250;
  DateTime _b2bPickupDate = DateTime.now().add(const Duration(days: 1));
  String _b2bTimeSlot = '08:00 - 12:00 (Early Commercial)';
  bool _b2bLoading = false;
  List<Map<String, dynamic>> _b2bInvoices = [];

  @override
  void initState() {
    super.initState();
    _service = widget.portalService ?? CustomerPortalService();
    _tabController = TabController(length: 2, vsync: this);
    _loadB2bInvoices();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _b2bCompanyController.dispose();
    _b2bTrnController.dispose();
    _b2bAddressController.dispose();
    _b2bNotesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadB2bInvoices() async {
    try {
      final list = await _service.getCorporateVatInvoices(corporateId: 'CORP-HYATT-DXB');
      if (mounted) {
        setState(() => _b2bInvoices = list);
      }
    } catch (_) {}
  }

  Future<void> _lookup() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    setState(() {
      _loading = true;
      _order = null;
      _errorMessage = null;
    });

    final notFoundMsg = mounted ? context.l10n.t('portal_not_found') : 'Order not found';
    try {
      final res = await _service.orderStatus(token);
      if (res.isNotEmpty) {
        _order = res;
      } else {
        _errorMessage = notFoundMsg;
      }
    } catch (_) {
      _errorMessage = notFoundMsg;
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }
  void _showScheduleDeliveryDialog() {
    final l10n = context.l10n;
    final addressCtrl = TextEditingController(text: _order?['delivery_address']?.toString() ?? 'Villa / Apt, Dubai');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String timeSlot = '14:00 - 18:00 (Afternoon)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.local_shipping, color: AppTheme.accentTeal),
              const SizedBox(width: 8),
              Text(l10n.t('portal_request_delivery')),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose preferred delivery date and time slot for your clean laundry items:',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.t('portal_address_label'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(selectedDate.year.toString() + '-' + selectedDate.month.toString().padLeft(2, '0') + '-' + selectedDate.day.toString().padLeft(2, '0')),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) setDlgState(() => selectedDate = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: timeSlot,
                  decoration: InputDecoration(labelText: l10n.t('portal_time_slot'), border: const OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: '09:00 - 13:00 (Morning)', child: Text('09:00 - 13:00 (Morning)')),
                    DropdownMenuItem(value: '14:00 - 18:00 (Afternoon)', child: Text('14:00 - 18:00 (Afternoon)')),
                    DropdownMenuItem(value: '18:00 - 22:00 (Evening VIP)', child: Text('18:00 - 22:00 (Evening VIP)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => timeSlot = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.t('cancel'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentTeal,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.t('portal_delivery_booked')),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              },
              child: Text(l10n.t('portal_confirm_delivery')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scheduleB2bPickup() async {
    setState(() => _b2bLoading = true);
    final l10n = context.l10n;
    try {
      final res = await _service.scheduleCorporatePickup(
        corporateId: 'CORP-HYATT-DXB',
        companyName: _b2bCompanyController.text.trim(),
        pickupAddress: _b2bAddressController.text.trim(),
        pickupDate: _b2bPickupDate,
        timeSlot: _b2bTimeSlot,
        estimatedGarmentCount: _b2bEstimatedGarments,
        notes: _b2bNotesController.text.trim(),
      );
      if (mounted) {
        setState(() => _b2bLoading = false);
        final ref = res['pickup_reference'] ?? 'B2B-PK-CONFIRMED';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.t('corporate_pickup_success') + ' Ref: #' + ref.toString()),
            backgroundColor: AppTokens.brandTeal,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _b2bLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ' + e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _downloadB2bConsolidatedStatement() async {
    final company = _b2bCompanyController.text.trim();
    final trn = _b2bTrnController.text.trim();
    final start = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final end = DateTime.now();

    try {
      final pdfBytes = await ReceiptRenderer.generateConsolidatedVatStatementPdf(
        corporateName: company,
        trn: trn,
        periodStart: start,
        periodEnd: end,
        orders: _b2bInvoices,
      );
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => Uint8List.fromList(pdfBytes),
        name: 'UAE_VAT_Consolidated_Statement.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate statement: ' + e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  int _getStatusStep(String? status) {
    switch (status?.toLowerCase()) {
      case 'received':
      case 'pending':
        return 0;
      case 'processing':
      case 'washing':
      case 'cleaning':
        return 1;
      case 'ready':
        return 2;
      case 'delivered':
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('customer_portal')),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTokens.cyberAqua,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(icon: const Icon(Icons.person_pin), text: l10n.t('portal_tab_retail')),
            Tab(icon: const Icon(Icons.business_center), text: l10n.t('portal_tab_corporate')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRetailTab(context),
          _buildCorporateTab(context),
        ],
      ),
    );
  }

  Widget _buildRetailTab(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryNavy, AppTheme.primaryNavy.withValues(alpha: 0.85)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.local_laundry_service, color: AppTheme.accentTeal, size: 48),
                const SizedBox(height: 12),
                Text(
                  l10n.t('customer_portal'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Track laundry status, wash cycles, and collection readiness live',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      labelText: l10n.t('portal_token'),
                      hintText: l10n.t('portal_tracking_hint'),
                      prefixIcon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryNavy),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onSubmitted: (_) => _lookup(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.search),
                      label: Text(l10n.t('portal_track_button')),
                      onPressed: _loading ? null : _lookup,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),

          if (_errorMessage != null)
            Card(
              color: AppTheme.warningOrange.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.warningOrange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.warningOrange, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_order != null) ...[
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.t('order_no') + ': #' + (_order!['order_no'] ?? _order!['sales_order_id'] ?? 'N/A').toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.accentTeal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (_order!['status'] ?? '').toString().toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.accentTeal,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    Text(
                      l10n.t('portal_order_timeline'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _buildTimeline(context, _getStatusStep(_order!['status']?.toString())),

                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.t('total'),
                          style: const TextStyle(fontSize: 15, color: AppTheme.secondaryGrey),
                        ),
                        Text(
                          (_order!['grand_total'] ?? _order!['total'] ?? '0.00').toString() + ' AED',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppTheme.primaryNavy),
                            ),
                            icon: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryNavy),
                            label: Text(
                              l10n.t('portal_download_receipt'),
                              style: const TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              final orderNo = _order!['order_no']?.toString() ?? 'ORDER';
                              final total = double.tryParse((_order!['grand_total'] ?? _order!['total'] ?? 0).toString()) ?? 0.0;
                              final receipt = ReceiptModel(
                                orderNo: orderNo,
                                customerName: _order!['customer_name']?.toString() ?? 'Valued Customer',
                                customerPhone: _order!['customer_phone']?.toString(),
                                subtotal: total * 0.9523,
                                tax: total * 0.0476,
                                grandTotal: total,
                                amountPaid: total,
                                balanceDue: 0.0,
                                lines: [
                                  ReceiptLine(
                                    description: 'Laundry Cleaning & Care Services',
                                    quantity: 1,
                                    rate: total * 0.9523,
                                    amount: total * 0.9523,
                                  ),
                                ],
                              );
                              try {
                                final pdfBytes = await ReceiptRenderer.toA4Pdf(receipt);
                                await Printing.layoutPdf(
                                  onLayout: (PdfPageFormat format) async => Uint8List.fromList(pdfBytes),
                                  name: 'Tax_Invoice_' + orderNo + '.pdf',
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.t('portal_receipt_failed').replaceAll('{error}', e.toString()))),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.local_shipping),
                            label: Text(l10n.t('portal_schedule_delivery'), style: const TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => _showScheduleDeliveryDialog(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildCorporateTab(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTokens.royalAbyss, AppTokens.brandNavy],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTokens.cyberAqua.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTokens.cyberAqua.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.corporate_fare, color: AppTokens.cyberAqua, size: 40),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('portal_tab_corporate'),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Enterprise Hotel & Hospitality B2B Gateway · FTA Compliant Monthly Statements & Batch Logistics',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.royalGold,
                    foregroundColor: AppTokens.royalAbyss,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.file_download, size: 18),
                  label: Text(
                    l10n.t('corporate_download_vat_statement'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _downloadB2bConsolidatedStatement,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_send, color: AppTokens.brandTeal),
                      const SizedBox(width: 10),
                      Text(
                        l10n.t('corporate_schedule_pickup'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _b2bCompanyController,
                          decoration: InputDecoration(
                            labelText: l10n.t('corporate_client_name'),
                            prefixIcon: const Icon(Icons.business),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _b2bTrnController,
                          decoration: InputDecoration(
                            labelText: l10n.t('corporate_trn'),
                            prefixIcon: const Icon(Icons.receipt_long),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _b2bAddressController,
                    decoration: InputDecoration(
                      labelText: l10n.t('portal_address_label'),
                      prefixIcon: const Icon(Icons.location_on),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: Text(
                            'Pickup Date: ' + _b2bPickupDate.year.toString() + '-' + _b2bPickupDate.month.toString().padLeft(2, '0') + '-' + _b2bPickupDate.day.toString().padLeft(2, '0'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _b2bPickupDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 60)),
                            );
                            if (picked != null) setState(() => _b2bPickupDate = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _b2bTimeSlot,
                          decoration: InputDecoration(
                            labelText: l10n.t('portal_time_slot'),
                            border: const OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: '08:00 - 12:00 (Early Commercial)', child: Text('08:00 - 12:00 (Early Commercial)')),
                            DropdownMenuItem(value: '13:00 - 17:00 (Afternoon Batch)', child: Text('13:00 - 17:00 (Afternoon Batch)')),
                            DropdownMenuItem(value: '18:00 - 22:00 (Night Fleet Express)', child: Text('18:00 - 22:00 (Night Fleet Express)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _b2bTimeSlot = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 170,
                        child: DropdownButtonFormField<int>(
                          initialValue: _b2bEstimatedGarments,
                          decoration: InputDecoration(
                            labelText: l10n.t('corporate_est_garments'),
                            border: const OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 100, child: Text('100 Pcs')),
                            DropdownMenuItem(value: 250, child: Text('250 Pcs')),
                            DropdownMenuItem(value: 500, child: Text('500 Pcs')),
                            DropdownMenuItem(value: 1000, child: Text('1000+ Pcs')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _b2bEstimatedGarments = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _b2bNotesController,
                    decoration: InputDecoration(
                      labelText: 'Batch Instructions / Fabric Care Notes',
                      prefixIcon: const Icon(Icons.notes),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.brandTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _b2bLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send),
                      label: Text(
                        _b2bLoading ? 'Scheduling...' : l10n.t('corporate_schedule_pickup'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: _b2bLoading ? null : _scheduleB2bPickup,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Corporate Batch Invoices',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        avatar: const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                        label: Text(_b2bInvoices.length.toString() + ' Invoices'),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _b2bInvoices.length,
                    separatorBuilder: (context, idx) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final inv = _b2bInvoices[idx];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTokens.cyberAqua.withValues(alpha: 0.15),
                          child: const Icon(Icons.receipt, color: AppTokens.brandNavy, size: 20),
                        ),
                        title: Text((inv['order_no'] ?? '').toString() + ' · ' + (inv['reference'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Date: ' + (inv['date'] ?? '').toString() + ' · Taxable: AED ' + (inv['subtotal'] as num).toStringAsFixed(2) + ' · VAT (5%): AED ' + (inv['tax'] as num).toStringAsFixed(2)),
                        trailing: Text(
                          'AED ' + (inv['total'] as num).toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTokens.brandNavy),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, int activeStep) {
    final l10n = context.l10n;
    final steps = [
      {'title': l10n.t('portal_received'), 'icon': Icons.assignment_turned_in},
      {'title': l10n.t('portal_cleaning'), 'icon': Icons.local_laundry_service},
      {'title': l10n.t('portal_ready'), 'icon': Icons.check_circle},
      {'title': l10n.t('portal_delivered'), 'icon': Icons.done_all},
    ];

    return Column(
      children: List.generate(steps.length, (idx) {
        final isDone = idx <= activeStep;
        final isCurrent = idx == activeStep;
        final step = steps[idx];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isDone ? AppTheme.accentTeal : Colors.grey.shade300,
                  child: Icon(
                    step['icon'] as IconData,
                    size: 16,
                    color: isDone ? Colors.white : Colors.grey.shade600,
                  ),
                ),
                if (idx < steps.length - 1)
                  Container(
                    width: 2,
                    height: 28,
                    color: idx < activeStep ? AppTheme.accentTeal : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                step['title'] as String,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent
                      ? AppTheme.primaryNavy
                      : isDone
                          ? Colors.black87
                          : AppTheme.secondaryGrey,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
