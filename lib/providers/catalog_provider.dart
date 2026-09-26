import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundrypro_uae/models/service_model.dart';
import 'package:laundrypro_uae/services/catalog_service.dart';

final catalogServiceProvider = Provider<CatalogService>((ref) {
  return CatalogService();
});

final servicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  final catalogService = ref.watch(catalogServiceProvider);
  final data = await catalogService.listServices();
  return data.map((e) => ServiceModel.fromJson(e)).toList();
});

final productsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final catalogService = ref.watch(catalogServiceProvider);
  return await catalogService.listProducts();
});
