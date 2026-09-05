import 'package:laundrypro_uae/services/api_client.dart';

class ChannelService {
  ChannelService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _api.get('/channels');
    return List<Map<String, dynamic>>.from(res['data']?['channels'] as List? ?? []);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final res = await _api.post('/channels', body: body);
    return Map<String, dynamic>.from(res['data']?['channel'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> sendTest(int id, String recipient) async {
    final res = await _api.post('/channels/$id/test', body: {'recipient': recipient});
    return Map<String, dynamic>.from(res['data']?['message'] as Map? ?? {});
  }
}
