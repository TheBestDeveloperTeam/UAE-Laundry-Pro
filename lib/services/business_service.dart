import 'package:laundrypro_uae/services/api_client.dart';

class BusinessService {
  BusinessService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<Map<String, dynamic>> getProfile() async {
    final res = await _api.get('/business');
    return Map<String, dynamic>.from(res['data']?['business'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    final res = await _api.put('/business', body: body);
    return Map<String, dynamic>.from(res['data']?['business'] as Map? ?? {});
  }
}
