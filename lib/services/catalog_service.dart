import 'package:laundrypro_uae/services/api_client.dart';

class CatalogService {
  CatalogService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listServices() async {
    final res = await _api.get('/services');
    return (res['data']?['services'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> listProducts({String? barcode}) async {
    final query = barcode != null && barcode.isNotEmpty
        ? '/products?barcode=${Uri.encodeQueryComponent(barcode)}'
        : '/products';
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

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> body) async {
    final res = await _api.post('/products', body: body);
    return Map<String, dynamic>.from(res['data']?['product'] as Map? ?? {});
  }
}
