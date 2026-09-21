import 'package:laundrypro_uae/services/api_client.dart';
import '../models/challan_model.dart';

class ChallanService {
  ChallanService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<ChallanModel>> list({String? challanType}) async {
    final path = challanType != null ? '/challans?challan_type=$challanType' : '/challans';
    final res = await _api.get(path);
    return (res['data']?['challans'] as List? ?? [])
        .map((e) => ChallanModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChallanModel> create(Map<String, dynamic> body) async {
    final res = await _api.post('/challans', body: body);
    return ChallanModel.fromMap(res['data']?['challan'] as Map<String, dynamic>? ?? {});
  }

  Future<ChallanModel> cancel(int id) async {
    final res = await _api.post('/challans/$id/cancel');
    return ChallanModel.fromMap(res['data']?['challan'] as Map<String, dynamic>? ?? {});
  }
}
