import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/product.dart';

class ProductsService {
  ProductsService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.productsCollection);

  Stream<List<Product>> watchProducts() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> saveProduct(Product product) async {
    if (product.id.isEmpty) {
      await _collection.add(product.toMap());
      return;
    }
    await _collection.doc(product.id).set(product.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteProduct(String id) => _collection.doc(id).delete();
}
