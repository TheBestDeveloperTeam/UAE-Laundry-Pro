import 'package:laundrypro_uae/services/api_client.dart';
import 'package:laundrypro_uae/models/customer_model.dart';

class CustomerService {
  CustomerService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<CustomerModel>> list({String? query}) async {
    final path = query != null && query.isNotEmpty ? '/customers?q=$query' : '/customers';
    final res = await _api.get(path);
    return (res['data']?['customers'] as List? ?? [])
        .map((e) => CustomerModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<CustomerModel> create(Map<String, dynamic> body) async {
    final res = await _api.post('/customers', body: body);
    return CustomerModel.fromJson(Map<String, dynamic>.from(res['data']?['customer'] as Map? ?? {}));
  }

  Future<CustomerModel> update(int id, Map<String, dynamic> body) async {
    final res = await _api.put('/customers/$id', body: body);
    return CustomerModel.fromJson(Map<String, dynamic>.from(res['data']?['customer'] as Map? ?? {}));
  }
}
