import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalog_repository.dart';
import '../../data/local_catalog_repository.dart';
import '../../domain/product.dart';

enum SortOption { newest, priceLow, priceHigh }

class CatalogFilter {
  const CatalogFilter({
    this.query = '',
    this.segment = 'الكل',
    this.category = 'الكل',
    this.priceRange = 1000,
    this.sort = SortOption.newest,
    this.featuredOnly = false,
  });

  final String query;
  final String segment;
  final String category;
  final double priceRange;
  final SortOption sort;
  final bool featuredOnly;

  CatalogFilter copyWith({
    String? query,
    String? segment,
    String? category,
    double? priceRange,
    SortOption? sort,
    bool? featuredOnly,
  }) {
    return CatalogFilter(
      query: query ?? this.query,
      segment: segment ?? this.segment,
      category: category ?? this.category,
      priceRange: priceRange ?? this.priceRange,
      sort: sort ?? this.sort,
      featuredOnly: featuredOnly ?? this.featuredOnly,
    );
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return LocalCatalogRepository();
});

final productsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(catalogRepositoryProvider).fetchProducts();
});

// Riverpod keeps the storefront and admin dashboard predictable across web and desktop.
final catalogFilterProvider =
    StateProvider<CatalogFilter>((ref) => const CatalogFilter());

final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final filter = ref.watch(catalogFilterProvider);

  return productsAsync.whenData((products) {
    final filtered = products.where((product) {
      final matchesQuery = filter.query.isEmpty ||
          product.name.contains(filter.query) ||
          product.brand.contains(filter.query) ||
          product.productNumber.contains(filter.query) ||
          product.segment.contains(filter.query) ||
          product.category.contains(filter.query);
      final matchesSegment =
          filter.segment == 'الكل' || product.segment == filter.segment;
      final matchesCategory =
          filter.category == 'الكل' || product.category == filter.category;
      final matchesPrice = product.price <= filter.priceRange;
      final matchesFeatured = !filter.featuredOnly || product.isFeatured;
      return matchesQuery &&
          matchesSegment &&
          matchesCategory &&
          matchesPrice &&
          matchesFeatured;
    }).toList();

    switch (filter.sort) {
      case SortOption.priceLow:
        filtered.sort((a, b) => a.price.compareTo(b.price));
      case SortOption.priceHigh:
        filtered.sort((a, b) => b.price.compareTo(a.price));
      case SortOption.newest:
        filtered.sort((a, b) => b.id.compareTo(a.id));
    }

    return filtered;
  });
});
