import 'package:cloud_firestore/cloud_firestore.dart';

const Duration kProductReservationDuration = Duration(minutes: 15);
const String kAllProductsSegment = 'الكل';
const String kMenSegment = 'رجالي';
const String kWomenSegment = 'ستاتي';
const String kAntiqueSegment = 'أنتيكا';
const String kProductStatusAvailable = 'available';
const String kProductStatusReserved = 'reserved';
const String kProductStatusSold = 'sold';
const String kApprovalStatusApproved = 'approved';
const String kApprovalStatusPending = 'pending';
const String kApprovalStatusRejected = 'rejected';
const double kMediatorSellingCommissionRate = 0.025;

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
    this.ownerName = '',
    this.ownerPhone = '',
    this.mediatorId = '',
    this.mediatorCode = '',
    this.listingStatus = kProductStatusAvailable,
    this.approvalStatus = kApprovalStatusApproved,
    this.listedByMediatorId = '',
    this.listedByMediatorCode = '',
    this.listedByMediatorName = '',
    this.soldByMediatorId = '',
    this.soldByMediatorCode = '',
    this.soldByMediatorName = '',
    this.reservedByMediatorId = '',
    this.reservedByMediatorCode = '',
    this.reservedByMediatorName = '',
    this.buyerName = '',
    this.buyerPhone = '',
    this.buyerAddress = '',
    this.lastAction = '',
    this.lastInquiryAt,
    this.reservedAt,
    this.soldAt,
    this.updatedAt,
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
  final String ownerName;
  final String ownerPhone;
  final String mediatorId;
  final String mediatorCode;
  final String listingStatus;
  final String approvalStatus;
  final String listedByMediatorId;
  final String listedByMediatorCode;
  final String listedByMediatorName;
  final String soldByMediatorId;
  final String soldByMediatorCode;
  final String soldByMediatorName;
  final String reservedByMediatorId;
  final String reservedByMediatorCode;
  final String reservedByMediatorName;
  final String buyerName;
  final String buyerPhone;
  final String buyerAddress;
  final String lastAction;
  final DateTime? lastInquiryAt;
  final DateTime? reservedAt;
  final DateTime? soldAt;
  final DateTime? updatedAt;

  bool get isSold => listingStatus == kProductStatusSold;
  bool get isApproved => approvalStatus == kApprovalStatusApproved;
  bool get isPendingApproval => approvalStatus == kApprovalStatusPending;
  bool get isRejected => approvalStatus == kApprovalStatusRejected;
  bool get hasActiveReservation => remainingReservation != Duration.zero;
  bool get isReserved =>
      listingStatus == kProductStatusReserved && hasActiveReservation;
  bool get isAvailable => stock > 0 && !isSold && !isReserved && isApproved;
  bool get isVisibleOnStorefront => !isSold && isApproved;

  DateTime? get reservationExpiresAt =>
      reservedAt?.add(kProductReservationDuration);

  Duration get remainingReservation {
    final expiresAt = reservationExpiresAt;
    if (expiresAt == null) return Duration.zero;
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  double get effectivePrice => price ?? 0;
  double get listingShare => 0;
  double get sellingShare =>
      soldByMediatorCode.isNotEmpty
          ? effectivePrice * kMediatorSellingCommissionRate
          : 0;
  double get companyShare => effectivePrice - sellingShare;
  double get mediatorBalance => sellingShare;

  String get displayName =>
      name.trim().isEmpty ? 'المنتج رقم $productNumber' : name.trim();

  String get storefrontSegment {
    final raw = segment.trim().isNotEmpty ? segment.trim() : category.trim();
    if (raw.contains('رجالي')) return kMenSegment;
    if (raw.contains('ستاتي') || raw.contains('نسائي')) return kWomenSegment;
    if (raw.contains('انتيكا') || raw.contains('أنتيكا')) return kAntiqueSegment;
    return raw;
  }

  String get statusKey {
    if (isSold) return kProductStatusSold;
    if (isReserved) return kProductStatusReserved;
    return kProductStatusAvailable;
  }

  String get statusLabel {
    switch (statusKey) {
      case kProductStatusReserved:
        return 'محجوز';
      case kProductStatusSold:
        return 'تم البيع';
      default:
        return 'متاح';
    }
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
    String? ownerName,
    String? ownerPhone,
    String? mediatorId,
    String? mediatorCode,
    String? listingStatus,
    String? approvalStatus,
    String? listedByMediatorId,
    String? listedByMediatorCode,
    String? listedByMediatorName,
    String? soldByMediatorId,
    String? soldByMediatorCode,
    String? soldByMediatorName,
    String? reservedByMediatorId,
    String? reservedByMediatorCode,
    String? reservedByMediatorName,
    String? buyerName,
    String? buyerPhone,
    String? buyerAddress,
    String? lastAction,
    DateTime? lastInquiryAt,
    DateTime? reservedAt,
    DateTime? soldAt,
    DateTime? updatedAt,
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
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      mediatorId: mediatorId ?? this.mediatorId,
      mediatorCode: mediatorCode ?? this.mediatorCode,
      listingStatus: listingStatus ?? this.listingStatus,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      listedByMediatorId: listedByMediatorId ?? this.listedByMediatorId,
      listedByMediatorCode: listedByMediatorCode ?? this.listedByMediatorCode,
      listedByMediatorName: listedByMediatorName ?? this.listedByMediatorName,
      soldByMediatorId: soldByMediatorId ?? this.soldByMediatorId,
      soldByMediatorCode: soldByMediatorCode ?? this.soldByMediatorCode,
      soldByMediatorName: soldByMediatorName ?? this.soldByMediatorName,
      reservedByMediatorId:
          reservedByMediatorId ?? this.reservedByMediatorId,
      reservedByMediatorCode:
          reservedByMediatorCode ?? this.reservedByMediatorCode,
      reservedByMediatorName:
          reservedByMediatorName ?? this.reservedByMediatorName,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      buyerAddress: buyerAddress ?? this.buyerAddress,
      lastAction: lastAction ?? this.lastAction,
      lastInquiryAt: lastInquiryAt ?? this.lastInquiryAt,
      reservedAt: reservedAt ?? this.reservedAt,
      soldAt: soldAt ?? this.soldAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': displayName,
      'productNumber': productNumber,
      'category': category,
      'brand': brand,
      'description': description,
      'stock': stock,
      'isFeatured': isFeatured,
      'createdAt': Timestamp.fromDate(createdAt),
      'price': price,
      'imageUrl': imageUrl,
      'segment': storefrontSegment,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'mediatorId': mediatorId,
      'mediatorCode': mediatorCode,
      'listingStatus': listingStatus,
      'approvalStatus': approvalStatus,
      'listedByMediatorId': listedByMediatorId,
      'listedByMediatorCode': listedByMediatorCode,
      'listedByMediatorName': listedByMediatorName,
      'soldByMediatorId': soldByMediatorId,
      'soldByMediatorCode': soldByMediatorCode,
      'soldByMediatorName': soldByMediatorName,
      'reservedByMediatorId': reservedByMediatorId,
      'reservedByMediatorCode': reservedByMediatorCode,
      'reservedByMediatorName': reservedByMediatorName,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerAddress': buyerAddress,
      'lastAction': lastAction,
      'lastInquiryAt':
          lastInquiryAt == null ? null : Timestamp.fromDate(lastInquiryAt!),
      'reservedAt': reservedAt == null ? null : Timestamp.fromDate(reservedAt!),
      'soldAt': soldAt == null ? null : Timestamp.fromDate(soldAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    DateTime? readDate(String key) {
      final value = map[key];
      return value is Timestamp ? value.toDate() : null;
    }

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
      segment: map['segment'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      ownerPhone: map['ownerPhone'] as String? ?? '',
      mediatorId: map['mediatorId'] as String? ?? '',
      mediatorCode: (map['mediatorCode'] as String? ?? '').toUpperCase(),
      listingStatus:
          map['listingStatus'] as String? ?? kProductStatusAvailable,
      approvalStatus:
          map['approvalStatus'] as String? ?? kApprovalStatusApproved,
      listedByMediatorId: map['listedByMediatorId'] as String? ?? '',
      listedByMediatorCode:
          (map['listedByMediatorCode'] as String? ?? '').toUpperCase(),
      listedByMediatorName: map['listedByMediatorName'] as String? ?? '',
      soldByMediatorId: map['soldByMediatorId'] as String? ?? '',
      soldByMediatorCode:
          (map['soldByMediatorCode'] as String? ?? '').toUpperCase(),
      soldByMediatorName: map['soldByMediatorName'] as String? ?? '',
      reservedByMediatorId: map['reservedByMediatorId'] as String? ?? '',
      reservedByMediatorCode:
          (map['reservedByMediatorCode'] as String? ?? '').toUpperCase(),
      reservedByMediatorName: map['reservedByMediatorName'] as String? ?? '',
      buyerName: map['buyerName'] as String? ?? '',
      buyerPhone: map['buyerPhone'] as String? ?? '',
      buyerAddress: map['buyerAddress'] as String? ?? '',
      lastAction: map['lastAction'] as String? ?? '',
      lastInquiryAt: readDate('lastInquiryAt'),
      reservedAt: readDate('reservedAt'),
      soldAt: readDate('soldAt'),
      updatedAt: readDate('updatedAt'),
    );
  }
}
