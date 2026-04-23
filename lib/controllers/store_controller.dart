import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/antique_product.dart';
import '../models/app_stats.dart';
import '../models/cart_item.dart';
import '../models/product_filters.dart';
import '../services/antique_catalog_service.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final antiqueCatalogServiceProvider = Provider<AntiqueCatalogService>((ref) {
  return AntiqueCatalogService(ref.watch(firestoreProvider));
});

final catalogProvider = StreamProvider<List<AntiqueProduct>>((ref) {
  return ref.watch(antiqueCatalogServiceProvider).watchProducts();
});

final featuredProductsProvider = Provider<List<AntiqueProduct>>((ref) {
  final products = ref.watch(catalogProvider).valueOrNull ?? const <AntiqueProduct>[];
  final featured = products.where((product) => product.isFeatured).take(4).toList(growable: false);
  return featured.isNotEmpty ? featured : products.take(4).toList(growable: false);
});

final categoriesProvider = Provider<List<String>>((ref) {
  final products = ref.watch(catalogProvider).valueOrNull ?? const <AntiqueProduct>[];
  final values = products.map((product) => product.category).toSet().toList()..sort();
  return values;
});

final erasProvider = Provider<List<String>>((ref) {
  final products = ref.watch(catalogProvider).valueOrNull ?? const <AntiqueProduct>[];
  final values = products.map((product) => product.era).toSet().toList()..sort();
  return values;
});

class ProductFiltersNotifier extends Notifier<ProductFilters> {
  @override
  ProductFilters build() => const ProductFilters();

  void setQuery(String value) {
    state = state.copyWith(query: value);
  }

  void setCategory(String? value) {
    state = state.copyWith(category: value);
  }

  void setEra(String? value) {
    state = state.copyWith(era: value);
  }

  void setMinPrice(double? value) {
    state = state.copyWith(minPrice: value);
  }

  void setMaxPrice(double? value) {
    state = state.copyWith(maxPrice: value);
  }

  void reset() {
    state = const ProductFilters();
  }
}

final productFiltersProvider = NotifierProvider<ProductFiltersNotifier, ProductFilters>(
  ProductFiltersNotifier.new,
);

final filteredProductsProvider = Provider<List<AntiqueProduct>>((ref) {
  final products = ref.watch(catalogProvider).valueOrNull ?? const <AntiqueProduct>[];
  final filters = ref.watch(productFiltersProvider);
  return products.where(filters.matches).toList(growable: false);
});

class CartNotifier extends Notifier<CartItem?> {
  @override
  CartItem? build() => null;

  void setProduct(AntiqueProduct product) {
    state = CartItem(product: product);
  }

  void clear() {
    state = null;
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartItem?>(CartNotifier.new);

final cartItemsCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider) == null ? 0 : 1;
});

final cartSubtotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider)?.totalPrice ?? 0;
});

class AppStatsNotifier extends Notifier<AppStats> {
  @override
  AppStats build() => const AppStats();

  void recordHomeVisit() {
    state = state.copyWith(homeVisits: state.homeVisits + 1);
  }

  void recordShopVisit() {
    state = state.copyWith(shopVisits: state.shopVisits + 1);
  }

  void recordCartVisit() {
    state = state.copyWith(cartVisits: state.cartVisits + 1);
  }

  void recordProductView(String productName) {
    state = state.copyWith(
      productViews: state.productViews + 1,
      lastViewedProductName: productName,
    );
  }

  void recordAddToCart(String productName) {
    state = state.copyWith(
      addToCartClicks: state.addToCartClicks + 1,
      lastViewedProductName: productName,
    );
  }

  void recordOrderRequest() {
    state = state.copyWith(orderRequests: state.orderRequests + 1);
  }

  void recordImagePreview() {
    state = state.copyWith(imagePreviewOpens: state.imagePreviewOpens + 1);
  }
}

final appStatsProvider = NotifierProvider<AppStatsNotifier, AppStats>(AppStatsNotifier.new);
