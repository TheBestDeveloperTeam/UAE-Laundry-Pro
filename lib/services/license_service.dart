import 'package:laundrypro_uae/services/api_client.dart';

class LicenseService {
  LicenseService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<Map<String, dynamic>> status() async {
    final res = await _api.get('/license/status');
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> activate(String licenseKey) async {
    final res = await _api.post('/license/activate', body: {'license_key': licenseKey});
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }
}
