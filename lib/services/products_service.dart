import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/polling_stream.dart';
import '../models/product.dart';

class ProductsService {
  ProductsService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.productsCollection);

  Stream<List<Product>> watchProducts() {
    return pollingListStream(fetchProducts);
  }

  Stream<List<Product>> watchMediatorProducts(String mediatorCode) {
    return pollingListStream(() => fetchMediatorProducts(mediatorCode));
  }

  Future<List<Product>> fetchProducts() async {
    final snapshot = await _collection.get().timeout(const Duration(seconds: 12));
    final products = <Product>[];
    for (final doc in snapshot.docs) {
      try {
        products.add(Product.fromMap(doc.id, doc.data()));
      } catch (_) {}
    }
    products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return products;
  }

  Future<List<Product>> fetchMediatorProducts(String mediatorCode) async {
    final snapshot = await _collection
        .where('mediatorCode', isEqualTo: mediatorCode.toUpperCase())
        .get()
        .timeout(const Duration(seconds: 12));
    final products = <Product>[];
    for (final doc in snapshot.docs) {
      try {
        products.add(Product.fromMap(doc.id, doc.data()));
      } catch (_) {}
    }
    products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return products;
  }

  Future<void> saveProduct(Product product) async {
    if (product.id.isEmpty) {
      await _collection.add(product.toMap());
      return;
    }
    await _collection.doc(product.id).set(product.toMap(), SetOptions(merge: true));
  }

  Future<void> updateProductStatus({
    required String productId,
    required String status,
    String mediatorId = '',
    String mediatorCode = '',
  }) {
    final now = DateTime.now();
    return _collection.doc(productId).set(
      {
        'listingStatus': status,
        'mediatorId': mediatorId,
        'mediatorCode': mediatorCode,
        'reservedAt': status == 'reserved' ? Timestamp.fromDate(now) : null,
        'soldAt': status == 'sold' ? Timestamp.fromDate(now) : null,
        'updatedAt': Timestamp.fromDate(now),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteProduct(String id) => _collection.doc(id).delete();
}
