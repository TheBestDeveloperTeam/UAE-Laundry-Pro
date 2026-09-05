import 'package:laundrypro_uae/services/api_client.dart';

class BackupService {
  BackupService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<Map<String, dynamic>> run() async {
    final res = await _api.post('/backup/run');
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }

  Future<List<Map<String, dynamic>>> history() async {
    final res = await _api.get('/backup/history');
    return (res['data']?['backups'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> verify({String? file}) async {
    final res = await _api.post('/backup/verify', body: {if (file != null) 'file': file});
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> restoreValidate({String? file}) async {
    final res = await _api.post('/backup/restore/validate', body: {if (file != null) 'file': file});
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }
}
