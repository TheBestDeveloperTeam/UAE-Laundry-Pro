import 'package:laundrypro_uae/services/api_client.dart';

class InstallService {
  InstallService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<Map<String, dynamic>> status() async {
    final res = await _api.get('/install/status', auth: false);
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }
}
