import '../domain/product.dart';

abstract class CatalogRepository {
  Future<List<Product>> fetchProducts();
}
