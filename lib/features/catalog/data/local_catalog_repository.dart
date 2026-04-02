import '../domain/product.dart';
import 'catalog_repository.dart';
import 'dummy_products.dart';

class LocalCatalogRepository implements CatalogRepository {
  @override
  Future<List<Product>> fetchProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return dummyProducts;
  }
}
