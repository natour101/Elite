import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/product.dart';

class ProductsService {
  ProductsService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.productsCollection);

  Stream<List<Product>> watchProducts() {
    return _collection.snapshots().map((snapshot) {
      final products = snapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    });
  }

  Stream<List<Product>> watchMediatorProducts(String mediatorCode) {
    return _collection
        .where('mediatorCode', isEqualTo: mediatorCode.toUpperCase())
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    });
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
