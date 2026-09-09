import 'package:laundrypro_uae/services/api_client.dart';

class CatalogService {
  CatalogService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listServices({int? parentId}) async {
    final query = parentId != null ? '/services?parent_id=$parentId' : '/services';
    final res = await _api.get(query);
    return (res['data']?['services'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> listProducts({String? barcode, int? parentId}) async {
    String query = '/products';
    final params = <String>[];
    if (barcode != null && barcode.isNotEmpty) {
      params.add('barcode=${Uri.encodeQueryComponent(barcode)}');
    }
    if (parentId != null) {
      params.add('parent_id=$parentId');
    }
    if (params.isNotEmpty) {
      query += '?${params.join('&')}';
    }

    final res = await _api.get(query);
    return (res['data']?['products'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>?> findProductByBarcode(String barcode) async {
    final products = await listProducts(barcode: barcode);
    if (products.isEmpty) return null;
    return products.first;
  }

  Future<Map<String, dynamic>> createService(Map<String, dynamic> body) async {
    final res = await _api.post('/services', body: body);
    return Map<String, dynamic>.from(res['data']?['service'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> updateService(int id, Map<String, dynamic> body) async {
    final res = await _api.put('/services/$id', body: body);
    return Map<String, dynamic>.from(res['data']?['service'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> body) async {
    final res = await _api.post('/products', body: body);
    return Map<String, dynamic>.from(res['data']?['product'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> body) async {
    final res = await _api.put('/products/$id', body: body);
    return Map<String, dynamic>.from(res['data']?['product'] as Map? ?? {});
  }

  Future<List<Map<String, dynamic>>> listServiceModifiers(int serviceId) async {
    final res = await _api.get('/services/$serviceId/modifiers');
    return (res['data']?['modifiers'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createServiceModifier(int serviceId, Map<String, dynamic> body) async {
    final res = await _api.post('/services/$serviceId/modifiers', body: body);
    return Map<String, dynamic>.from(res['data']?['modifier'] as Map? ?? {});
  }

  Future<List<Map<String, dynamic>>> listProductModifiers(int productId) async {
    final res = await _api.get('/products/$productId/modifiers');
    return (res['data']?['modifiers'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createProductModifier(int productId, Map<String, dynamic> body) async {
    final res = await _api.post('/products/$productId/modifiers', body: body);
    return Map<String, dynamic>.from(res['data']?['modifier'] as Map? ?? {});
  }
}
