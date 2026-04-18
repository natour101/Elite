import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../services/cloudinary_service.dart';
import '../services/products_service.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final productsServiceProvider = Provider<ProductsService>((ref) {
  return ProductsService(ref.watch(firestoreProvider));
});

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return const CloudinaryService();
});

class ProductsCatalogController extends AsyncNotifier<List<Product>> {
  Timer? _timer;

  @override
  Future<List<Product>> build() async {
    ref.onDispose(() => _timer?.cancel());
    _timer ??= Timer.periodic(
      const Duration(seconds: 8),
      (_) => unawaited(refresh(silent: true)),
    );
    return ref.read(productsServiceProvider).fetchProducts();
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      state = AsyncValue.data(state.valueOrNull ?? const <Product>[]);
    }
    state = await AsyncValue.guard(
      () => ref.read(productsServiceProvider).fetchProducts(),
    );
  }
}

final productsProvider =
    AsyncNotifierProvider<ProductsCatalogController, List<Product>>(
  ProductsCatalogController.new,
);

final storefrontProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref.watch(productsProvider).whenData(
        (products) =>
            products.where((product) => product.isVisibleOnStorefront).toList(),
      );
});

final storefrontSegmentFilterProvider =
    StateProvider<String>((ref) => kAllProductsSegment);

final filteredStorefrontProductsProvider =
    Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(storefrontProductsProvider);
  final filter = ref.watch(storefrontSegmentFilterProvider);
  return productsAsync.whenData((products) {
    if (filter == kAllProductsSegment) return products;
    return products
        .where((product) => product.storefrontSegment == filter)
        .toList();
  });
});
