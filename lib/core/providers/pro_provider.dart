import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../features/store/store_models.dart';
import '../services/store_service.dart';

final storeServiceProvider = Provider<StoreService>((ref) {
  return storeService;
});

final proStatusProvider = StreamProvider<ProStatus>((ref) async* {
  final service = ref.watch(storeServiceProvider);
  yield service.currentStatus;
  yield* service.proStatusStream;
});

final storeProductsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  final service = ref.watch(storeServiceProvider);
  if (service.availableProducts.isEmpty) {
    await service.loadProducts();
  }
  return service.availableProducts;
});

final purchasePendingProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(storeServiceProvider);
  yield false;
  yield* service.purchasePendingStream;
});

final purchaseErrorProvider = StreamProvider<String>((ref) async* {
  final service = ref.watch(storeServiceProvider);
  yield* service.purchaseErrorStream;
});
