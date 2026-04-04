import 'package:cloud_firestore/cloud_firestore.dart';

class MediatorProfile {
  const MediatorProfile({
    required this.id,
    required this.name,
    required this.location,
    required this.phone,
    required this.code,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String location;
  final String phone;
  final String code;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'phone': phone,
      'code': code,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MediatorProfile.fromMap(String id, Map<String, dynamic> map) {
    final createdAt = map['createdAt'];
    return MediatorProfile(
      id: id,
      name: map['name'] as String? ?? '',
      location: map['location'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      code: map['code'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }
}
