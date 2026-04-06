import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../services/products_service.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final productsServiceProvider = Provider<ProductsService>((ref) {
  return ProductsService(ref.watch(firestoreProvider));
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
    return _load();
  }

  Future<List<Product>> _load() {
    return ref.read(productsServiceProvider).fetchProducts();
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      final previous = state.valueOrNull ?? const <Product>[];
      state = AsyncValue.data(previous);
    }
    state = await AsyncValue.guard(_load);
  }
}

final productsProvider =
    AsyncNotifierProvider<ProductsCatalogController, List<Product>>(
  ProductsCatalogController.new,
);

final storefrontProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  return productsAsync.whenData(
    (products) => products.where((product) => product.isVisibleOnStorefront).toList(),
  );
});

final storefrontSegmentFilterProvider = StateProvider<String>((ref) => 'الكل');

final filteredStorefrontProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(storefrontProductsProvider);
  final filter = ref.watch(storefrontSegmentFilterProvider);
  return productsAsync.whenData((products) {
    if (filter == 'الكل') return products;
    return products.where((product) => product.storefrontSegment == filter).toList();
  });
});

class ProductFormData {
  const ProductFormData({
    required this.name,
    required this.productNumber,
    required this.category,
    required this.brand,
    required this.description,
    required this.stock,
    required this.isFeatured,
    this.price,
    this.imageUrl = '',
    this.id = '',
    this.createdAt,
    this.mediatorId = '',
    this.mediatorCode = '',
    this.listingStatus = 'active',
    this.segment = '',
  });

  final String id;
  final DateTime? createdAt;
  final String mediatorId;
  final String mediatorCode;
  final String listingStatus;
  final String segment;
  final String name;
  final String productNumber;
  final String category;
  final String brand;
  final String description;
  final int stock;
  final bool isFeatured;
  final double? price;
  final String imageUrl;

  Product toProduct() {
    return Product(
      id: id,
      name: name,
      productNumber: productNumber,
      category: category,
      brand: brand,
      description: description,
      stock: stock,
      isFeatured: isFeatured,
      price: price,
      imageUrl: imageUrl,
      createdAt: createdAt ?? DateTime.now(),
      mediatorId: mediatorId,
      mediatorCode: mediatorCode.trim().toUpperCase(),
      listingStatus: listingStatus,
      segment: segment,
    );
  }
}

class ProductActionsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> save(ProductFormData form) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(productsServiceProvider).saveProduct(form.toProduct()),
    );
    await ref.read(productsProvider.notifier).refresh();
  }

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(productsServiceProvider).deleteProduct(id),
    );
    await ref.read(productsProvider.notifier).refresh();
  }

  Future<void> updateStatus({
    required String productId,
    required String status,
    String mediatorId = '',
    String mediatorCode = '',
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(productsServiceProvider).updateProductStatus(
            productId: productId,
            status: status,
            mediatorId: mediatorId,
            mediatorCode: mediatorCode,
          ),
    );
    await ref.read(productsProvider.notifier).refresh();
  }
}

final productActionsControllerProvider =
    AsyncNotifierProvider<ProductActionsController, void>(
  ProductActionsController.new,
);
