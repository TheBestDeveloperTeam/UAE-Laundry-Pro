import 'package:laundrypro_uae/services/api_client.dart';

class ChallanService {
  ChallanService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list({String? challanType}) async {
    final path = challanType != null ? '/challans?challan_type=$challanType' : '/challans';
    final res = await _api.get(path);
    return (res['data']?['challans'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final res = await _api.post('/challans', body: body);
    return Map<String, dynamic>.from(res['data']?['challan'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> cancel(int id) async {
    final res = await _api.post('/challans/$id/cancel');
    return Map<String, dynamic>.from(res['data']?['challan'] as Map? ?? {});
  }
}
