import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import '../models/employee_model.dart';

final operatorServiceProvider = Provider((ref) => OperatorService(ref.read(apiClientProvider)));

class OperatorService {
  final ApiClient _api;

  OperatorService(this._api);

  Future<List<dynamic>> listCertifications() async {
    final res = await _api.get('/operators/certifications');
    return res['data']?['certifications'] as List? ?? [];
  }

  Future<List<EmployeeModel>> listEmployees() async {
    final res = await _api.get('/employees');
    return (res['data']?['employees'] as List? ?? [])
        .map((e) => EmployeeModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> certify(int employeeId, Map<String, dynamic> data) async {
    await _api.post('/operators/$employeeId/certify', body: data);
  }
}
