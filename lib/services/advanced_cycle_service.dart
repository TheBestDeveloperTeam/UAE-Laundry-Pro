import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final advancedCycleServiceProvider = Provider((ref) => AdvancedCycleService(ref.read(apiClientProvider)));

class AdvancedCycleService {
  final ApiClient _api;

  AdvancedCycleService(this._api);

  Future<List<dynamic>> getPresets() async {
    final res = await _api.get('/advanced-cycles/presets');
    return res['data'] ?? [];
  }

  Future<Map<String, dynamic>> startCycle(Map<String, dynamic> data) async {
    final res = await _api.post('/advanced-cycles/start', data: data);
    return res['data'] ?? {};
  }

  Future<void> completeCycle(String id, String condition) async {
    await _api.post('/advanced-cycles//complete', data: {'condition': condition});
  }

  Future<void> processLog(String id, Map<String, dynamic> data) async {
    await _api.post('/advanced-cycles//process-logs', data: data);
  }
}
