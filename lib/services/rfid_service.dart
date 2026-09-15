import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final rfidServiceProvider = Provider((ref) => RfidService(ref.read(apiClientProvider)));

class RfidService {
  final ApiClient _api;

  RfidService(this._api);

  Future<Map<String, dynamic>> scanTags(List<String> tags) async {
    final res = await _api.post('/rfid/scan', data: {'epc_tags': tags});
    return res['data'] ?? {};
  }
}

