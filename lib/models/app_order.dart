import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    this.price,
  });

  final String productId;
  final String name;
  final int quantity;
  final double? price;

  double? get lineTotal => price == null ? null : price! * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toDouble(),
    );
  }
}

class AppOrder {
  const AppOrder({
    required this.id,
    required this.items,
    required this.mediatorId,
    required this.mediatorCode,
    required this.mediatorName,
    required this.createdAt,
    required this.status,
    this.customerName = '',
    this.customerPhone = '',
    this.notes = '',
  });

  final String id;
  final List<OrderItem> items;
  final String mediatorId;
  final String mediatorCode;
  final String mediatorName;
  final DateTime createdAt;
  final String status;
  final String customerName;
  final String customerPhone;
  final String notes;

  int get totalQuantity =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  double get totalAmount => items.fold<double>(
        0,
        (sum, item) => sum + (item.lineTotal ?? 0),
      );

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'mediatorId': mediatorId,
      'mediatorCode': mediatorCode,
      'mediatorName': mediatorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'notes': notes,
      'totalQuantity': totalQuantity,
      'totalAmount': totalAmount,
    };
  }

  factory AppOrder.fromMap(String id, Map<String, dynamic> map) {
    final createdAt = map['createdAt'];
    final rawItems = (map['items'] as List<dynamic>? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return AppOrder(
      id: id,
      items: rawItems.map(OrderItem.fromMap).toList(),
      mediatorId: map['mediatorId'] as String? ?? '',
      mediatorCode: map['mediatorCode'] as String? ?? '',
      mediatorName: map['mediatorName'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      status: map['status'] as String? ?? 'pending',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }
}
