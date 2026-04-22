import 'antique_product.dart';

class ProductFilters {
  const ProductFilters({
    this.query = '',
    this.category,
    this.era,
    this.minPrice,
    this.maxPrice,
  });

  final String query;
  final String? category;
  final String? era;
  final double? minPrice;
  final double? maxPrice;

  ProductFilters copyWith({
    String? query,
    Object? category = _sentinel,
    Object? era = _sentinel,
    Object? minPrice = _sentinel,
    Object? maxPrice = _sentinel,
  }) {
    return ProductFilters(
      query: query ?? this.query,
      category: category == _sentinel ? this.category : category as String?,
      era: era == _sentinel ? this.era : era as String?,
      minPrice: minPrice == _sentinel ? this.minPrice : minPrice as double?,
      maxPrice: maxPrice == _sentinel ? this.maxPrice : maxPrice as double?,
    );
  }

  bool matches(AntiqueProduct product) {
    final normalizedQuery = query.trim().toLowerCase();
    final matchesQuery = normalizedQuery.isEmpty ||
        product.name.toLowerCase().contains(normalizedQuery) ||
        product.description.toLowerCase().contains(normalizedQuery) ||
        product.category.toLowerCase().contains(normalizedQuery);
    final matchesCategory = category == null || product.category == category;
    final matchesEra = era == null || product.era == era;
    final matchesMin = minPrice == null || product.price >= minPrice!;
    final matchesMax = maxPrice == null || product.price <= maxPrice!;
    return matchesQuery && matchesCategory && matchesEra && matchesMin && matchesMax;
  }
}

const _sentinel = Object();
