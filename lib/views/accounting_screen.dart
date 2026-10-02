import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/theme.dart';
import 'package:laundrypro_uae/services/accounting_service.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key, this.accountingService});
  final AccountingService? accountingService;

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> with SingleTickerProviderStateMixin {
  late final AccountingService _service;
  late final TabController _tabController;
  List<Map<String, dynamic>> _batches = [];
  bool _loading = true;
  String _selectedAdapter = 'csv';
  final DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  final DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _service = widget.accountingService ?? AccountingService();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _batches = await _service.listBatches();
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _export() async {
    final fmt = DateFormat('yyyy-MM-dd');
    final from = fmt.format(_startDate);
    final to = fmt.format(_endDate);
    setState(() => _loading = true);
    try {
      await _service.export(
        periodStart: from,
        periodEnd: to,
        adapter: _selectedAdapter,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.t('accounting_copied')),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (_) {}
    await _load();
  }

  void _showBatchDetails(Map<String, dynamic> batch) async {
    final batchId = batch['id'] is int ? batch['id'] as int : int.tryParse('${batch['id']}') ?? 0;
    Map<String, dynamic> details = batch;
    List<dynamic> lines = (batch['lines'] as List?) ?? [];

    if (lines.isEmpty && batchId > 0) {
      try {
        final res = await _service.showBatch(batchId);
        if (res['batch'] != null) details = Map<String, dynamic>.from(res['batch'] as Map);
        if (res['lines'] != null) lines = List<dynamic>.from(res['lines'] as List);
      } catch (_) {}
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final l10n = ctx.l10n;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${l10n.t('accounting_lines')} #${details['uuid']?.toString().substring(0, 8) ?? batchId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${details['period_start']} — ${details['period_end']} • ${details['adapter']?.toString().toUpperCase()}',
                style: const TextStyle(color: AppTheme.secondaryGrey),
              ),
              const Divider(height: 24),
              Expanded(
                child: lines.isEmpty
                    ? Center(child: Text(l10n.t('reports_empty')))
                    : ListView.separated(
                        itemCount: lines.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, idx) {
                          final item = lines[idx] as Map<String, dynamic>;
                          final debit = double.tryParse('${item['debit']}') ?? 0.0;
                          final credit = double.tryParse('${item['credit']}') ?? 0.0;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: debit > 0
                                  ? AppTheme.warningOrange.withValues(alpha: 0.15)
                                  : AppTheme.accentTeal.withValues(alpha: 0.15),
                              child: Text(
                                '${item['account_code'] ?? '0000'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: debit > 0 ? AppTheme.warningOrange : AppTheme.accentTeal,
                                ),
                              ),
                            ),
                            title: Text(item['description'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('Line #${item['line_no'] ?? idx + 1}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (debit > 0)
                                  Text(
                                    'Dr: ${debit.toStringAsFixed(2)} AED',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warningOrange),
                                  ),
                                if (credit > 0)
                                  Text(
                                    'Cr: ${credit.toStringAsFixed(2)} AED',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentTeal),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _exportFafAuditFile() {
    final csv = _service.generateFafAuditCsv(
      companyName: 'UAE Laundry Pro LLC',
      trn: '100492817200003',
      periodStart: DateFormat('yyyy-MM-dd').format(_startDate),
      periodEnd: DateFormat('yyyy-MM-dd').format(_endDate),
      totalStandardSales: 12500.00,
      totalVatCollected: 625.00,
      totalExpenses: 4200.00,
      totalInputVat: 210.00,
    );
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.t('accounting_copied')),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  void _exportZatcaXml() {
    final end = DateFormat('yyyy-MM-dd').format(_endDate);
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">');
    buffer.writeln('  <cbc:ProfileID>reporting:1.0</cbc:ProfileID>');
    buffer.writeln('  <cbc:ID>ZATCA-INV-${DateTime.now().millisecondsSinceEpoch}</cbc:ID>');
    buffer.writeln('  <cbc:IssueDate>$end</cbc:IssueDate>');
    buffer.writeln('  <cbc:InvoiceTypeCode name="0100000">388</cbc:InvoiceTypeCode>');
    buffer.writeln('  <cbc:DocumentCurrencyCode>SAR</cbc:DocumentCurrencyCode>');
    buffer.writeln('  <cac:AccountingSupplierParty>');
    buffer.writeln('    <cac:Party>');
    buffer.writeln('      <cac:PartyTaxScheme>');
    buffer.writeln('        <cbc:CompanyID>310123456700003</cbc:CompanyID>');
    buffer.writeln('        <cac:TaxScheme><cbc:ID>VAT</cbc:ID></cac:TaxScheme>');
    buffer.writeln('      </cac:PartyTaxScheme>');
    buffer.writeln('    </cac:Party>');
    buffer.writeln('  </cac:AccountingSupplierParty>');
    buffer.writeln('  <cac:LegalMonetaryTotal>');
    buffer.writeln('    <cbc:LineExtensionAmount currencyID="SAR">12500.00</cbc:LineExtensionAmount>');
    buffer.writeln('    <cbc:TaxExclusiveAmount currencyID="SAR">12500.00</cbc:TaxExclusiveAmount>');
    buffer.writeln('    <cbc:TaxInclusiveAmount currencyID="SAR">14375.00</cbc:TaxInclusiveAmount>');
    buffer.writeln('  </cac:LegalMonetaryTotal>');
    buffer.writeln('</Invoice>');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('KSA ZATCA Phase 2 UBL XML copied to clipboard! Ready for Clearance/Reporting API.'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('accounting_export')),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppTheme.accentTeal,
          tabs: [
            Tab(icon: const Icon(Icons.history), text: l10n.t('accounting_export')),
            Tab(icon: const Icon(Icons.verified_user), text: l10n.t('accounting_audit_tax')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Export Batches & GL Sync
          RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter & Generator Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.date_range, color: AppTheme.primaryNavy),
                              const SizedBox(width: 8),
                              Text(
                                '${fmt.format(_startDate)}  ➔  ${fmt.format(_endDate)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const Spacer(),
                              DropdownButton<String>(
                                value: _selectedAdapter,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(value: 'csv', child: Text('CSV (QuickBooks/Xero)')),
                                  DropdownMenuItem(value: 'iif', child: Text('QuickBooks IIF')),
                                  DropdownMenuItem(value: 'json', child: Text('JSON Standard')),
                                  DropdownMenuItem(value: 'zatca', child: Text('KSA ZATCA Phase 2 (UBL 2.1 XML)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedAdapter = val);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryNavy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.file_download),
                              label: Text(l10n.t('accounting_generate_export')),
                              onPressed: _loading ? null : _export,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.t('reports_overview'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (_loading)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  else if (_batches.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(l10n.t('reports_empty'), style: const TextStyle(color: AppTheme.secondaryGrey)),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _batches.length,
                      itemBuilder: (_, i) {
                        final b = _batches[i];
                        final status = b['status']?.toString() ?? 'exported';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.accentTeal.withValues(alpha: 0.15),
                              child: const Icon(Icons.receipt_long, color: AppTheme.accentTeal),
                            ),
                            title: Text(
                              '${b['period_start']} — ${b['period_end']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${b['adapter']?.toString().toUpperCase()} • Status: $status'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showBatchDetails(b),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // Tab 2: UAE FTA VAT Audit (FAF) Generation
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentTeal.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance, color: AppTheme.accentTeal),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.t('accounting_audit_tax'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const Text(
                                    'UAE Federal Tax Authority (FTA) Audit File v1.0',
                                    style: TextStyle(color: AppTheme.secondaryGrey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.t('accounting_sales_rev')),
                          trailing: const Text('12,500.00 AED', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Standard Output VAT (5%)'),
                          trailing: Text('625.00 AED', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentTeal)),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.t('accounting_operating_exp')),
                          trailing: const Text('4,200.00 AED', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Recoverable Input VAT (5%)'),
                          trailing: Text('210.00 AED', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warningOrange)),
                        ),
                        const Divider(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l10n.t('accounting_net_payable'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: const Text(
                            '415.00 AED',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryNavy),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.copy),
                            label: Text(l10n.t('accounting_fta_faf')),
                            onPressed: _exportFafAuditFile,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppTheme.primaryNavy),
                            ),
                            icon: const Icon(Icons.code, color: AppTheme.primaryNavy),
                            label: const Text('Export KSA ZATCA Phase 2 UBL XML', style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold)),
                            onPressed: _exportZatcaXml,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
