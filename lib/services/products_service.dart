import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/utils/polling_stream.dart';
import '../firebase_options.dart';
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
    if (kIsWeb) {
      return _fetchProductsFromRest();
    }

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
    if (kIsWeb) {
      final allProducts = await _fetchProductsFromRest();
      return allProducts
          .where((product) => product.mediatorCode == mediatorCode.toUpperCase())
          .toList();
    }

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

  Future<List<Product>> _fetchProductsFromRest() async {
    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/${DefaultFirebaseOptions.web.projectId}/databases/(default)/documents/${AppConstants.productsCollection}',
      {
        'key': DefaultFirebaseOptions.web.apiKey,
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('فشل تحميل المنتجات من Firestore REST: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = (body['documents'] as List<dynamic>? ?? const <dynamic>[]);
    final products = <Product>[];

    for (final document in documents) {
      try {
        final doc = document as Map<String, dynamic>;
        final namePath = (doc['name'] as String? ?? '');
        final id = namePath.split('/').isNotEmpty ? namePath.split('/').last : '';
        final fields = doc['fields'] as Map<String, dynamic>? ?? const <String, dynamic>{};
        products.add(Product.fromMap(id, _decodeDocument(fields)));
      } catch (_) {}
    }

    products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return products;
  }

  Map<String, dynamic> _decodeDocument(Map<String, dynamic> fields) {
    final map = <String, dynamic>{};
    fields.forEach((key, value) {
      map[key] = _decodeValue(value as Map<String, dynamic>);
    });
    return map;
  }

  dynamic _decodeValue(Map<String, dynamic> value) {
    if (value.containsKey('stringValue')) return value['stringValue'];
    if (value.containsKey('integerValue')) {
      return int.tryParse('${value['integerValue']}') ?? 0;
    }
    if (value.containsKey('doubleValue')) {
      return (value['doubleValue'] as num).toDouble();
    }
    if (value.containsKey('booleanValue')) return value['booleanValue'] as bool;
    if (value.containsKey('timestampValue')) {
      return Timestamp.fromDate(DateTime.parse(value['timestampValue'] as String));
    }
    if (value.containsKey('nullValue')) return null;
    if (value.containsKey('mapValue')) {
      final nested = value['mapValue'] as Map<String, dynamic>;
      final nestedFields =
          nested['fields'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      return _decodeDocument(nestedFields);
    }
    if (value.containsKey('arrayValue')) {
      final arrayValue = value['arrayValue'] as Map<String, dynamic>;
      final values = arrayValue['values'] as List<dynamic>? ?? const <dynamic>[];
      return values
          .map((item) => _decodeValue(item as Map<String, dynamic>))
          .toList();
    }
    return null;
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
