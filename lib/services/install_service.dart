import 'package:laundrypro_uae/services/api_client.dart';

class InstallService {
  InstallService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<Map<String, dynamic>> status() async {
    final res = await _api.get('/install/status', auth: false);
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> migrate({String? installToken}) async {
    final headers = installToken != null && installToken.isNotEmpty ? {'X-Install-Token': installToken} : null;
    final res = await _api.post('/install/migrate', auth: false, customHeaders: headers);
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> seed({String? adminPassword, String? installToken}) async {
    final headers = installToken != null && installToken.isNotEmpty ? {'X-Install-Token': installToken} : null;
    final res = await _api.post('/install/seed', body: adminPassword != null ? {'admin_password': adminPassword} : null, auth: false, customHeaders: headers);
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> complete({String? installToken}) async {
    final headers = installToken != null && installToken.isNotEmpty ? {'X-Install-Token': installToken} : null;
    final res = await _api.post('/install/complete', auth: false, customHeaders: headers);
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }
}

