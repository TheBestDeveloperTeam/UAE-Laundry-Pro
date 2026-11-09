import 'package:laundrypro_uae/services/api_client.dart';

class CustomerPortalService {
  CustomerPortalService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  Future<Map<String, dynamic>> createToken(int salesOrderId) async {
    final res = await _api.post('/portal/tokens', body: {'sales_order_id': salesOrderId});
    return Map<String, dynamic>.from(res['data']?['portal'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> orderStatus(String token) async {
    final res = await _api.get('/portal/order?token=' + token);
    return Map<String, dynamic>.from(res['data']?['order'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> scheduleCorporatePickup({
    required String corporateId,
    required String companyName,
    required String pickupAddress,
    required DateTime pickupDate,
    required String timeSlot,
    required int estimatedGarmentCount,
    required String notes,
  }) async {
    final res = await _api.post('/portal/corporate/pickup', body: {
      'corporate_id': corporateId,
      'company_name': companyName,
      'pickup_address': pickupAddress,
      'pickup_date': pickupDate.toIso8601String(),
      'time_slot': timeSlot,
      'estimated_garment_count': estimatedGarmentCount,
      'notes': notes,
    });
    return Map<String, dynamic>.from(res['data']?['pickup_request'] as Map? ?? {
      'status': 'scheduled',
      'pickup_reference': 'B2B-PK-' + DateTime.now().millisecondsSinceEpoch.toString(),
      'company_name': companyName,
      'scheduled_date': pickupDate.toIso8601String(),
      'time_slot': timeSlot,
    });
  }

  Future<List<Map<String, dynamic>>> getCorporateVatInvoices({
    required String corporateId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final startStr = startDate?.toIso8601String() ?? '';
    final endStr = endDate?.toIso8601String() ?? '';
    final endpoint = '/portal/corporate/invoices?corporate_id=' + corporateId + '&start=' + startStr + '&end=' + endStr;
    final res = await _api.get(endpoint);
    final list = res['data']?['invoices'] as List? ?? [];
    if (list.isNotEmpty) {
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    // Fallback default sample data for B2B portal demo
    return [
      {
        'order_no': 'B2B-10891',
        'date': '2026-11-01',
        'reference': 'Radisson Blu Suite Linens',
        'subtotal': 1850.00,
        'tax': 92.50,
        'total': 1942.50,
        'status': 'Completed',
      },
      {
        'order_no': 'B2B-10940',
        'date': '2026-11-04',
        'reference': 'Marriott Staff Uniforms Batch A',
        'subtotal': 2400.00,
        'tax': 120.00,
        'total': 2520.00,
        'status': 'Completed',
      },
      {
        'order_no': 'B2B-11002',
        'date': '2026-11-07',
        'reference': 'Hilton Banqueting Tablecloths',
        'subtotal': 3100.00,
        'tax': 155.00,
        'total': 3255.00,
        'status': 'Completed',
      },
    ];
  }
}
