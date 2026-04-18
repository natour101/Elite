import 'package:cloud_firestore/cloud_firestore.dart';

class Mediator {
  const Mediator({
    required this.id,
    required this.name,
    this.code = '',
    this.username = '',
    this.phone = '',
    this.location = '',
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String name;
  final String code;
  final String username;
  final String phone;
  final String location;
  final bool isActive;
  final DateTime? createdAt;

  String get subtitle {
    if (location.isNotEmpty && phone.isNotEmpty) {
      return '$location • $phone';
    }
    if (location.isNotEmpty) return location;
    if (phone.isNotEmpty) return phone;
    return 'وسيط معتمد من Elite';
  }

  String get loginKey => username.isNotEmpty ? username : code;

  Mediator copyWithId(String nextId) {
    return Mediator(
      id: nextId,
      name: name,
      code: code,
      username: username,
      phone: phone,
      location: location,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code.toUpperCase(),
      'username': username.toUpperCase(),
      'phone': phone,
      'location': location,
      'isActive': isActive,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }

  factory Mediator.fromMap(String id, Map<String, dynamic> map) {
    String readString(List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return '';
    }

    final createdAt = map['createdAt'];

    return Mediator(
      id: id,
      name: readString(['name', 'fullName', 'displayName', 'mediatorName']),
      code: readString(['code', 'mediatorCode']).toUpperCase(),
      username: readString(['username', 'login', 'userName']).toUpperCase(),
      phone: readString(['phone', 'mobile', 'phoneNumber', 'contactPhone']),
      location: readString(['location', 'city', 'address', 'area']),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}
