import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final advancedCycleServiceProvider = Provider((ref) => AdvancedCycleService(ref.read(apiClientProvider)));

class AdvancedCycleService {
  final ApiClient _api;

  AdvancedCycleService(this._api);

  Future<List<dynamic>> getPresets() async {
    final res = await _api.get('/advanced-cycles/presets');
    return res['data']?['presets'] as List? ?? [];
  }

  Future<Map<String, dynamic>> startCycle(Map<String, dynamic> data) async {
    final res = await _api.post('/advanced-cycles/start', data: data);
    return res['data'] ?? {};
  }

  Future<void> completeCycle(dynamic id, String condition) async {
    await _api.post('/advanced-cycles/$id/complete', data: {'condition': condition});
  }

  Future<Map<String, dynamic>> processLog(dynamic id, Map<String, dynamic> data) async {
    final res = await _api.post('/advanced-cycles/$id/process-logs', data: data);
    return res['data'] ?? {};
  }
}
