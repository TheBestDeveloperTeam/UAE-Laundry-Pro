import 'package:laundrypro_uae/services/api_client.dart';
import 'package:laundrypro_uae/models/employee_model.dart';

class EmployeeService {
  EmployeeService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<EmployeeModel>> list({String? query}) async {
    final path = query != null && query.isNotEmpty ? '/employees?q=$query' : '/employees';
    final res = await _api.get(path);
    return (res['data']?['employees'] as List? ?? [])
        .map((e) => EmployeeModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<EmployeeModel> create(Map<String, dynamic> body) async {
    final res = await _api.post('/employees', body: body);
    return EmployeeModel.fromJson(Map<String, dynamic>.from(res['data']?['employee'] as Map? ?? {}));
  }

  Future<EmployeeModel> update(int id, Map<String, dynamic> body) async {
    final res = await _api.put('/employees/$id', body: body);
    return EmployeeModel.fromJson(Map<String, dynamic>.from(res['data']?['employee'] as Map? ?? {}));
  }

  Future<bool> deactivate(int id) async {
    try {
      await _api.delete('/employees/$id');
      return true;
    } catch (_) {
      return false;
    }
  }
}

