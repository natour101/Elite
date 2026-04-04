import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../services/products_service.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final productsServiceProvider = Provider<ProductsService>((ref) {
  return ProductsService(ref.watch(firestoreProvider));
});

final productsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productsServiceProvider).watchProducts();
});

class ProductFormData {
  const ProductFormData({
    required this.name,
    required this.productNumber,
    required this.category,
    required this.brand,
    required this.description,
    required this.stock,
    required this.isFeatured,
    this.price,
    this.imageUrl = '',
    this.id = '',
    this.createdAt,
  });

  final String id;
  final DateTime? createdAt;
  final String name;
  final String productNumber;
  final String category;
  final String brand;
  final String description;
  final int stock;
  final bool isFeatured;
  final double? price;
  final String imageUrl;

  Product toProduct() {
    return Product(
      id: id,
      name: name,
      productNumber: productNumber,
      category: category,
      brand: brand,
      description: description,
      stock: stock,
      isFeatured: isFeatured,
      price: price,
      imageUrl: imageUrl,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}

class ProductActionsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> save(ProductFormData form) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(productsServiceProvider).saveProduct(form.toProduct()),
    );
  }

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(productsServiceProvider).deleteProduct(id),
    );
  }
}

final productActionsControllerProvider =
    AsyncNotifierProvider<ProductActionsController, void>(
  ProductActionsController.new,
);
