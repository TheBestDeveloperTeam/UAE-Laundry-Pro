import 'package:laundrypro_uae/services/api_client.dart';

class SettingsService {
  SettingsService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<Map<String, dynamic>> getSettings() async {
    final res = await _api.get('/settings');
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    final res = await _api.put('/settings', body: {'settings': settings});
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }
}
