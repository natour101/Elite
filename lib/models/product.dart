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
    this.segment = '',
    this.mediatorId = '',
    this.mediatorCode = '',
    this.listingStatus = 'active',
    this.reservedAt,
    this.soldAt,
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
  final String segment;
  final String mediatorId;
  final String mediatorCode;
  final String listingStatus;
  final DateTime? reservedAt;
  final DateTime? soldAt;

  bool get isAvailable => stock > 0 && listingStatus != 'sold';
  bool get isVisibleOnStorefront => listingStatus != 'sold';
  bool get isReserved => listingStatus == 'reserved';
  bool get isSold => listingStatus == 'sold';
  String get storefrontSegment {
    final rawSegment = segment.trim();
    if (rawSegment.isNotEmpty) return rawSegment;

    final rawCategory = category.trim();
    if (rawCategory.contains('رجالي')) return 'رجالي';
    if (rawCategory.contains('ستاتي') || rawCategory.contains('نسائي')) {
      return 'ستاتي';
    }

    return '';
  }

  Product copyWith({
    String? id,
    String? name,
    String? productNumber,
    String? category,
    String? brand,
    String? description,
    int? stock,
    bool? isFeatured,
    DateTime? createdAt,
    double? price,
    String? imageUrl,
    String? segment,
    String? mediatorId,
    String? mediatorCode,
    String? listingStatus,
    DateTime? reservedAt,
    DateTime? soldAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      productNumber: productNumber ?? this.productNumber,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      stock: stock ?? this.stock,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      segment: segment ?? this.segment,
      mediatorId: mediatorId ?? this.mediatorId,
      mediatorCode: mediatorCode ?? this.mediatorCode,
      listingStatus: listingStatus ?? this.listingStatus,
      reservedAt: reservedAt ?? this.reservedAt,
      soldAt: soldAt ?? this.soldAt,
    );
  }

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
      'segment': segment,
      'mediatorId': mediatorId,
      'mediatorCode': mediatorCode,
      'listingStatus': listingStatus,
      'reservedAt': reservedAt == null ? null : Timestamp.fromDate(reservedAt!),
      'soldAt': soldAt == null ? null : Timestamp.fromDate(soldAt!),
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    final createdAt = map['createdAt'];
    final reservedAt = map['reservedAt'];
    final soldAt = map['soldAt'];

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
      segment: map['segment'] as String? ?? '',
      mediatorId: map['mediatorId'] as String? ?? '',
      mediatorCode: (map['mediatorCode'] as String? ?? '').toUpperCase(),
      listingStatus: map['listingStatus'] as String? ?? 'active',
      reservedAt: reservedAt is Timestamp ? reservedAt.toDate() : null,
      soldAt: soldAt is Timestamp ? soldAt.toDate() : null,
    );
  }
}
