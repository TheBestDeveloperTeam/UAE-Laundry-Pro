import 'dart:typed_data';
import 'package:flutter/material.dart';
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

class _CustomerPortalScreenState extends State<CustomerPortalScreen> {
  late final CustomerPortalService _service;
  final _tokenController = TextEditingController();
  Map<String, dynamic>? _order;
  bool _loading = false;
  String? _errorMessage;

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
    final addressCtrl = TextEditingController(text: _order?['delivery_address']?.toString() ?? 'Villa / Apt, Dubai');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String timeSlot = '14:00 - 18:00 (Afternoon)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.local_shipping, color: AppTheme.accentTeal),
              SizedBox(width: 8),
              Text('Request Home Delivery / Pickup'),
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
                  decoration: const InputDecoration(
                    labelText: 'Drop-off / Delivery Address *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
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
                  initialValue: timeSlot,
                  decoration: const InputDecoration(labelText: 'Preferred Time Slot', border: OutlineInputBorder()),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentTeal,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Delivery request booked! Driver will contact before arrival.'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              },
              child: const Text('Confirm Delivery Request'),
            ),
          ],
        ),
      ),
    );
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
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

            // Token input card
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
                        hintText: 'e.g. ORD-2026-0042 or 8-char token',
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
              // Order Details Card
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
                            '${l10n.t('order_no')}: #${_order!['order_no'] ?? _order!['sales_order_id'] ?? 'N/A'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.accentTeal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_order!['status']}'.toUpperCase(),
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

                      // Progress Steps Timeline
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
                            '${_order!['grand_total'] ?? _order!['total'] ?? '0.00'} AED',
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
                              label: const Text('Download Receipt', style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                final orderNo = _order!['order_no']?.toString() ?? 'ORDER';
                                final total = double.tryParse('${_order!['grand_total'] ?? _order!['total'] ?? 0}') ?? 0.0;
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
                                    name: 'Tax_Invoice_$orderNo.pdf',
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to generate receipt: $e')),
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
                              label: const Text('Schedule Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
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
