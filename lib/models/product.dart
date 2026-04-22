import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';

const Duration kProductReservationDuration = Duration(
  minutes: AppConstants.mediatorReservationMinutes,
);
const String kAllProductsSegment = 'الكل';
const String kMenSegment = 'رجالي';
const String kWomenSegment = 'ستاتي';
const String kAntiqueSegment = 'أنتيكا';
const String kProductStatusAvailable = 'available';
const String kProductStatusReserved = 'reserved';
const String kProductStatusSaleRequested = 'sale_requested';
const String kProductStatusSold = 'sold';
const String kProductStatusDelivered = 'delivered';
const String kApprovalStatusApproved = 'approved';
const String kApprovalStatusPending = 'pending';
const String kApprovalStatusRejected = 'rejected';

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
    this.mediatorCommission,
    this.reservationDurationMinutes = AppConstants.mediatorReservationMinutes,
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
    this.saleRequestedAt,
    this.soldAt,
    this.deliveredAt,
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
  final double? mediatorCommission;
  final int reservationDurationMinutes;
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
  final DateTime? saleRequestedAt;
  final DateTime? soldAt;
  final DateTime? deliveredAt;
  final DateTime? updatedAt;

  bool get isDelivered => listingStatus == kProductStatusDelivered;
  bool get isSold =>
      listingStatus == kProductStatusSold || listingStatus == kProductStatusDelivered;
  bool get isSaleRequested => listingStatus == kProductStatusSaleRequested;
  bool get isApproved => approvalStatus == kApprovalStatusApproved;
  bool get isPendingApproval => approvalStatus == kApprovalStatusPending;
  bool get isRejected => approvalStatus == kApprovalStatusRejected;
  bool get hasActiveReservation =>
      listingStatus == kProductStatusReserved && remainingReservation != Duration.zero;
  bool get isReserved => hasActiveReservation;
  bool get isAvailable => stock > 0 && statusKey == kProductStatusAvailable && isApproved;
  bool get isVisibleOnStorefront =>
      !isSold && !isSaleRequested && isApproved;
  bool get canBeReservedByMediator => isApproved && !isSold && !isSaleRequested;
  bool get countsTowardRevenue => isDelivered;

  DateTime? get reservationExpiresAt => reservedAt?.add(
        Duration(minutes: reservationDurationMinutes),
      );

  Duration get remainingReservation {
    final expiresAt = reservationExpiresAt;
    if (expiresAt == null || listingStatus != kProductStatusReserved) {
      return Duration.zero;
    }
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  double get effectivePrice => price ?? 0;
  double get effectiveMediatorCommission =>
      mediatorCommission ??
      (effectivePrice * AppConstants.defaultMediatorCommissionRate);
  double get listingShare => 0;
  double get sellingShare =>
      soldByMediatorCode.isNotEmpty && countsTowardRevenue
          ? effectiveMediatorCommission
          : 0;
  double get companyShare =>
      countsTowardRevenue ? math.max(0, effectivePrice - sellingShare) : 0;
  double get mediatorBalance => sellingShare;

  String get displayName =>
      name.trim().isEmpty ? 'المنتج رقم $productNumber' : name.trim();

  String get storefrontSegment {
    final raw = segment.trim().isNotEmpty ? segment.trim() : category.trim();
    if (raw.contains('رجالي')) return kMenSegment;
    if (raw.contains('ستاتي') || raw.contains('نسائي')) return kWomenSegment;
    if (raw.contains('انتيكا') || raw.contains('أنتيكا')) return kAntiqueSegment;
    return raw.isEmpty ? kAllProductsSegment : raw;
  }

  String get statusKey {
    if (isDelivered) return kProductStatusDelivered;
    if (listingStatus == kProductStatusSold) return kProductStatusSold;
    if (listingStatus == kProductStatusSaleRequested) {
      return kProductStatusSaleRequested;
    }
    if (hasActiveReservation) return kProductStatusReserved;
    return kProductStatusAvailable;
  }

  String get statusLabel {
    switch (statusKey) {
      case kProductStatusReserved:
        return 'محجوز';
      case kProductStatusSaleRequested:
        return 'بانتظار تأكيد الإدارة';
      case kProductStatusSold:
        return 'تم البيع';
      case kProductStatusDelivered:
        return 'تم التوصيل';
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
    double? mediatorCommission,
    int? reservationDurationMinutes,
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
    DateTime? saleRequestedAt,
    DateTime? soldAt,
    DateTime? deliveredAt,
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
      mediatorCommission: mediatorCommission ?? this.mediatorCommission,
      reservationDurationMinutes:
          reservationDurationMinutes ?? this.reservationDurationMinutes,
      listingStatus: listingStatus ?? this.listingStatus,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      listedByMediatorId: listedByMediatorId ?? this.listedByMediatorId,
      listedByMediatorCode:
          listedByMediatorCode ?? this.listedByMediatorCode,
      listedByMediatorName:
          listedByMediatorName ?? this.listedByMediatorName,
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
      saleRequestedAt: saleRequestedAt ?? this.saleRequestedAt,
      soldAt: soldAt ?? this.soldAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
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
      'mediatorCommission': mediatorCommission,
      'reservationDurationMinutes': reservationDurationMinutes,
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
      'saleRequestedAt':
          saleRequestedAt == null ? null : Timestamp.fromDate(saleRequestedAt!),
      'soldAt': soldAt == null ? null : Timestamp.fromDate(soldAt!),
      'deliveredAt':
          deliveredAt == null ? null : Timestamp.fromDate(deliveredAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    DateTime? readDate(String key) {
      final value = map[key];
      if (value is Timestamp) return value.toDate();
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
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
      mediatorCommission: (map['mediatorCommission'] as num?)?.toDouble(),
      reservationDurationMinutes:
          (map['reservationDurationMinutes'] as num?)?.toInt() ??
              AppConstants.mediatorReservationMinutes,
      listingStatus: map['listingStatus'] as String? ?? kProductStatusAvailable,
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
      saleRequestedAt: readDate('saleRequestedAt'),
      soldAt: readDate('soldAt'),
      deliveredAt: readDate('deliveredAt'),
      updatedAt: readDate('updatedAt'),
    );
  }
}
