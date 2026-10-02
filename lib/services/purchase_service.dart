import 'package:laundrypro_uae/services/api_client.dart';
import '../models/purchase_order_model.dart';

class PurchaseService {
  PurchaseService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<PurchaseOrderModel>> list({String? status}) async {
    final path = status != null ? '/purchase-orders?status=$status' : '/purchase-orders';
    final res = await _api.get(path);
    return (res['data']?['purchase_orders'] as List? ?? [])
        .map((e) => PurchaseOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PurchaseOrderModel> create(Map<String, dynamic> body) async {
    final res = await _api.post('/purchase-orders', body: body);
    return PurchaseOrderModel.fromJson(res['data']?['purchase_order'] as Map<String, dynamic>? ?? {});
  }

  Future<PurchaseOrderModel> get(int id) async {
    final res = await _api.get('/purchase-orders/$id');
    return PurchaseOrderModel.fromJson(res['data']?['purchase_order'] as Map<String, dynamic>? ?? {});
  }

  Future<PurchaseOrderModel> receive(int id, Map<String, dynamic> body) async {
    final res = await _api.post('/purchase-orders/$id/receive', body: body);
    return PurchaseOrderModel.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }
}
