import 'package:laundrypro_uae/services/api_client.dart';
import 'package:laundrypro_uae/models/branch_model.dart';

class BranchService {
  BranchService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  Future<List<BranchModel>> list() async {
    final res = await _api.get('/branches');
    final list = res['data']?['branches'] as List? ?? [];
    return list.map((e) => BranchModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<BranchModel> create(Map<String, dynamic> body) async {
    final res = await _api.post('/branches', body: body);
    return BranchModel.fromJson(Map<String, dynamic>.from(res['data']?['branch'] as Map? ?? {}));
  }

  Future<BranchModel> update(int id, Map<String, dynamic> body) async {
    final res = await _api.put('/branches/$id', body: body);
    return BranchModel.fromJson(Map<String, dynamic>.from(res['data']?['branch'] as Map? ?? {}));
  }
}
