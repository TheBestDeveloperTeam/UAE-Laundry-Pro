import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import '../models/inventory_model.dart';

final equipmentServiceProvider = Provider((ref) => EquipmentService(ref.read(apiClientProvider)));

class EquipmentService {
  final ApiClient _api;

  EquipmentService(this._api);

  Future<List<InventoryModel>> listAll() async {
    final res = await _api.get('/equipment');
    return (res['data']['equipment'] as List? ?? [])
        .map((e) => InventoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> logCalibration(int equipmentId, Map<String, dynamic> data) async {
    await _api.post('/equipment/\/calibrate', data: data);
  }

  Future<void> setOutOfService(int equipmentId, bool outOfService) async {
    await _api.post('/equipment/\/status', data: {'out_of_service': outOfService});
  }
}

