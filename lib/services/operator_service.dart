import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final operatorServiceProvider = Provider((ref) => OperatorService(ref.read(apiClientProvider)));

class OperatorService {
  final ApiClient _api;

  OperatorService(this._api);

  Future<List<dynamic>> listCertifications() async {
    final res = await _api.get('/operators/certifications');
    return res['data']['certifications'] ?? [];
  }

  Future<void> certify(int employeeId, Map<String, dynamic> data) async {
    await _api.post('/operators/\/certify', data: data);
  }
}

