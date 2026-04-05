import 'package:cloud_firestore/cloud_firestore.dart';

class PublicationRequest {
  const PublicationRequest({
    required this.id,
    required this.mediatorId,
    required this.mediatorCode,
    required this.mediatorName,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.createdAt,
    this.price,
    this.imageUrl = '',
    this.status = 'pending',
  });

  final String id;
  final String mediatorId;
  final String mediatorCode;
  final String mediatorName;
  final String name;
  final String brand;
  final String category;
  final String description;
  final DateTime createdAt;
  final double? price;
  final String imageUrl;
  final String status;

  Map<String, dynamic> toMap() {
    return {
      'mediatorId': mediatorId,
      'mediatorCode': mediatorCode,
      'mediatorName': mediatorName,
      'name': name,
      'brand': brand,
      'category': category,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'price': price,
      'imageUrl': imageUrl,
      'status': status,
    };
  }

  factory PublicationRequest.fromMap(String id, Map<String, dynamic> map) {
    final createdAt = map['createdAt'];
    return PublicationRequest(
      id: id,
      mediatorId: map['mediatorId'] as String? ?? '',
      mediatorCode: map['mediatorCode'] as String? ?? '',
      mediatorName: map['mediatorName'] as String? ?? '',
      name: map['name'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      category: map['category'] as String? ?? '',
      description: map['description'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      price: (map['price'] as num?)?.toDouble(),
      imageUrl: map['imageUrl'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
    );
  }
}
