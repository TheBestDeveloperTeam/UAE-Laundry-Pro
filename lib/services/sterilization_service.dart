import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final sterilizationServiceProvider = Provider((ref) => SterilizationService(ref.read(apiClientProvider)));

class SterilizationService {
  final ApiClient _api;

  SterilizationService(this._api);

  Future<Map<String, dynamic>> batchCreate(Map<String, dynamic> data) async {
    final res = await _api.post('/sterilization/batch', data: data);
    return res['data'] ?? {};
  }

  Future<Map<String, dynamic>> batchScan(Map<String, dynamic> data) async {
    final res = await _api.post('/sterilization/scan', data: data);
    return res['data'] ?? {};
  }

  Future<Map<String, dynamic>> logSterilization(Map<String, dynamic> data) async {
    final res = await _api.post('/sterilization/log', data: data);
    return res['data'] ?? {};
  }

  Future<Map<String, dynamic>> signElectronic(Map<String, dynamic> data) async {
    final res = await _api.post('/sterilization/sign', data: data);
    return res['data'] ?? {};
  }

  Future<List<dynamic>> listLogs(String cycleRunId) async {
    final res = await _api.get('/sterilization/logs/');
    return res['data']['logs'] ?? [];
  }
}

