import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.productNumber,
    required this.category,
    required this.brand,
    required this.description,
    required this.stock,
    required this.isFeatured,
    required this.createdAt,
    this.price,
    this.imageUrl = '',
  });

  final String id;
  final String name;
  final String productNumber;
  final String category;
  final String brand;
  final String description;
  final int stock;
  final bool isFeatured;
  final DateTime createdAt;
  final double? price;
  final String imageUrl;

  bool get isAvailable => stock > 0;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'productNumber': productNumber,
      'category': category,
      'brand': brand,
      'description': description,
      'stock': stock,
      'isFeatured': isFeatured,
      'createdAt': Timestamp.fromDate(createdAt),
      'price': price,
      'imageUrl': imageUrl,
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    final createdAt = map['createdAt'];
    return Product(
      id: id,
      name: map['name'] as String? ?? '',
      productNumber: map['productNumber'] as String? ?? '',
      category: map['category'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      description: map['description'] as String? ?? '',
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      isFeatured: map['isFeatured'] as bool? ?? false,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      price: (map['price'] as num?)?.toDouble(),
      imageUrl: map['imageUrl'] as String? ?? '',
    );
  }
}
