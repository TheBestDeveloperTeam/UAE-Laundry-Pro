import 'package:laundrypro_uae/services/api_client.dart';

class AccountingService {
  AccountingService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listBatches() async {
    final res = await _api.get('/accounting/batches');
    return List<Map<String, dynamic>>.from(res['data']?['batches'] as List? ?? []);
  }

  Future<Map<String, dynamic>> showBatch(int id) async {
    final res = await _api.get('/accounting/batches/$id');
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> export({
    required String periodStart,
    required String periodEnd,
    String adapter = 'csv',
  }) async {
    final res = await _api.post('/accounting/export', body: {
      'period_start': periodStart,
      'period_end': periodEnd,
      'adapter': adapter,
    });
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }

  /// Generates UAE FTA Audit File (FAF) compliant CSV structure
  String generateFafAuditCsv({
    required String companyName,
    required String trn,
    required String periodStart,
    required String periodEnd,
    required double totalStandardSales,
    required double totalVatCollected,
    required double totalExpenses,
    required double totalInputVat,
  }) {
    final buffer = StringBuffer();
    // Company Header Record
    buffer.writeln('CompanyInfo,TaxablePersonName,TRN,PeriodStart,PeriodEnd,CreationDate');
    buffer.writeln('"$companyName","$trn","$periodStart","$periodEnd","${DateTime.now().toIso8601String().substring(0, 10)}"');
    buffer.writeln();

    // Standard Rated Supplies (Box 1a)
    buffer.writeln('StandardRatedSupplies,TransactionType,TaxRate,NetTotalAED,VATAED');
    buffer.writeln('Supplies,Standard,5%,${totalStandardSales.toStringAsFixed(2)},${totalVatCollected.toStringAsFixed(2)}');
    buffer.writeln();

    // Standard Rated Expenses / Recoverable Input Tax (Box 9)
    buffer.writeln('StandardRatedExpenses,TransactionType,TaxRate,NetTotalAED,RecoverableVATAED');
    buffer.writeln('InputExpenses,Standard,5%,${totalExpenses.toStringAsFixed(2)},${totalInputVat.toStringAsFixed(2)}');
    buffer.writeln();

    // Net Payable / Refundable
    final netPayable = totalVatCollected - totalInputVat;
    buffer.writeln('VATSummary,GrossSalesAED,GrossOutputVatAED,GrossInputVatAED,NetPayableDueAED');
    buffer.writeln('Summary,${(totalStandardSales + totalVatCollected).toStringAsFixed(2)},${totalVatCollected.toStringAsFixed(2)},${totalInputVat.toStringAsFixed(2)},${netPayable.toStringAsFixed(2)}');

    return buffer.toString();
  }
}
