import 'package:laundrypro_uae/services/api_client.dart';

class LocalizationService {
  LocalizationService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> profiles() async {
    final res = await _api.get('/localization/profiles');
    return List<Map<String, dynamic>>.from(res['data']?['profiles'] as List? ?? []);
  }

  Future<Map<String, dynamic>> setCountry(String code) async {
    final res = await _api.put('/localization/country', body: {'country_code': code});
    return Map<String, dynamic>.from(res['data']?['profile'] as Map? ?? {});
  }
}
