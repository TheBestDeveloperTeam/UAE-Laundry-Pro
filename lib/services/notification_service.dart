import 'package:laundrypro_uae/services/api_client.dart';

class NotificationService {
  NotificationService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list({bool unreadOnly = false}) async {
    final path = unreadOnly ? '/notifications?unread=1' : '/notifications';
    final res = await _api.get(path);
    return (res['data']?['notifications'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> markRead(int id) async {
    final res = await _api.post('/notifications/$id/read');
    return Map<String, dynamic>.from(res['data']?['notification'] as Map? ?? {});
  }

  Future<int> markAllRead() async {
    final res = await _api.post('/notifications/read-all');
    return (res['data']?['marked_count'] as num?)?.toInt() ?? 0;
  }
}
