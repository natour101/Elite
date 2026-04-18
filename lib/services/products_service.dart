import 'dart:convert';
import 'dart:math';

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

  static const _productCodeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

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
      throw Exception(
        'فشل تحميل المنتجات من Firestore REST: ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = body['documents'] as List<dynamic>? ?? const <dynamic>[];
    final products = <Product>[];

    for (final document in documents) {
      try {
        final doc = document as Map<String, dynamic>;
        final namePath = doc['name'] as String? ?? '';
        final id = namePath.split('/').isNotEmpty ? namePath.split('/').last : '';
        final fields = doc['fields'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
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
    final normalizedNumber = product.productNumber.trim().isEmpty
        ? await generateUniqueProductNumber()
        : product.productNumber.trim().toUpperCase();

    final existing = await _collection
        .where('productNumber', isEqualTo: normalizedNumber)
        .get()
        .timeout(const Duration(seconds: 12));

    for (final doc in existing.docs) {
      if (doc.id != product.id) {
        throw Exception('رقم المنتج مستخدم مسبقاً داخل النظام.');
      }
    }

    final payload = product
        .copyWith(
          productNumber: normalizedNumber,
          updatedAt: DateTime.now(),
        )
        .toMap();

    if (product.id.isEmpty) {
      await _collection.add(payload);
      return;
    }
    await _collection.doc(product.id).set(payload, SetOptions(merge: true));
  }

  Future<String> generateUniqueProductNumber({int length = 5}) async {
    final random = Random.secure();

    for (var attempt = 0; attempt < 40; attempt++) {
      final candidate = List.generate(
        length,
        (_) => _productCodeChars[random.nextInt(_productCodeChars.length)],
      ).join();
      final existing = await _collection
          .where('productNumber', isEqualTo: candidate)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 12));
      if (existing.docs.isEmpty) return candidate;
    }

    throw Exception('تعذر توليد رقم منتج فريد حالياً، حاول مرة أخرى.');
  }

  Future<void> approveProduct({
    required String productId,
    required bool approved,
  }) {
    return _collection.doc(productId).set(
      {
        'approvalStatus':
            approved ? kApprovalStatusApproved : kApprovalStatusRejected,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> markProductSold({
    required Product product,
    required String buyerPhone,
    required String buyerAddress,
    String soldByMediatorId = '',
    String soldByMediatorCode = '',
    String soldByMediatorName = '',
  }) async {
    final now = DateTime.now();
    final productRef = _collection.doc(product.id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(productRef);
      if (!snapshot.exists) {
        throw Exception('المنتج غير موجود حالياً.');
      }

      final currentProduct = Product.fromMap(product.id, snapshot.data()!);
      if (currentProduct.isSold) {
        throw Exception('تم بيع هذا المنتج مسبقاً.');
      }

      transaction.set(
        productRef,
        {
          'listingStatus': kProductStatusSold,
          'soldAt': Timestamp.fromDate(now),
          'reservedAt': null,
          'buyerPhone': buyerPhone.trim(),
          'buyerAddress': buyerAddress.trim(),
          'lastAction': 'sold',
          'soldByMediatorId': soldByMediatorId,
          'soldByMediatorCode': soldByMediatorCode.toUpperCase(),
          'soldByMediatorName': soldByMediatorName,
          'updatedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<DateTime> reserveProduct({
    required Product product,
    String customerName = '',
    String customerLocation = '',
    String buyerPhone = '',
    String buyerAddress = '',
    String mediatorId = '',
    String mediatorCode = '',
    String mediatorName = '',
    String reservationSource = 'store_purchase',
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(kProductReservationDuration);
    final orderRef = _firestore.collection(AppConstants.ordersCollection).doc();
    final productRef = _collection.doc(product.id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(productRef);
      if (!snapshot.exists) {
        throw Exception('المنتج غير موجود حالياً.');
      }

      final currentProduct = Product.fromMap(product.id, snapshot.data()!);
      if (currentProduct.isSold) {
        throw Exception('هذا المنتج تم بيعه بالفعل.');
      }
      if (currentProduct.hasActiveReservation) {
        throw Exception('هذا المنتج محجوز حالياً ولا يمكن حجزه مرة أخرى.');
      }

      transaction.set(
        orderRef,
        {
          'productId': currentProduct.id,
          'productName': currentProduct.displayName,
          'productNumber': currentProduct.productNumber,
          'customerName': customerName.trim(),
          'customerLocation': customerLocation.trim(),
          'buyerPhone': buyerPhone.trim(),
          'buyerAddress': buyerAddress.trim(),
          'mediatorId': mediatorId,
          'mediatorCode': mediatorCode.toUpperCase(),
          'mediatorName': mediatorName,
          'source': reservationSource,
          'status': kProductStatusReserved,
          'createdAt': Timestamp.fromDate(now),
          'reservedUntil': Timestamp.fromDate(expiresAt),
        },
      );

      transaction.set(
        productRef,
        {
          'listingStatus': kProductStatusReserved,
          'mediatorId': mediatorId,
          'mediatorCode': mediatorCode.toUpperCase(),
          'reservedByMediatorId': mediatorId,
          'reservedByMediatorCode': mediatorCode.toUpperCase(),
          'reservedByMediatorName': mediatorName,
          'buyerName': customerName.trim(),
          'buyerPhone': buyerPhone.trim(),
          'buyerAddress': buyerAddress.trim(),
          'lastAction': reservationSource,
          'reservedAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );
    });

    return expiresAt;
  }

  Future<void> noteInquiry(Product product) {
    return _collection.doc(product.id).set(
      {
        'lastAction': 'inquiry',
        'lastInquiryAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteProduct(String id) => _collection.doc(id).delete();
}
