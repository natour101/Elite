import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../firebase_options.dart';
import '../models/mediator.dart';

class MediatorsService {
  MediatorsService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.mediatorsCollection);

  Future<List<Mediator>> fetchMediators() async {
    if (kIsWeb) {
      return _fetchMediatorsFromRest();
    }

    final snapshot = await _collection.get().timeout(const Duration(seconds: 12));
    final mediators = <Mediator>[];
    for (final doc in snapshot.docs) {
      try {
        final mediator = Mediator.fromMap(doc.id, doc.data());
        if (mediator.name.isNotEmpty) mediators.add(mediator);
      } catch (_) {}
    }
    mediators.sort((a, b) => a.name.compareTo(b.name));
    return mediators;
  }

  Future<Mediator?> findByLoginKey(String value) async {
    final normalized = value.trim().toUpperCase();
    if (normalized.isEmpty) return null;

    final mediators = await fetchMediators();
    for (final mediator in mediators) {
      if (!mediator.isActive) continue;
      if (mediator.code.toUpperCase() == normalized ||
          mediator.username.toUpperCase() == normalized) {
        return mediator;
      }
    }
    return null;
  }

  Future<void> saveMediator(Mediator mediator) async {
    final doc = mediator.id.isEmpty ? _collection.doc() : _collection.doc(mediator.id);
    await doc.set(
      mediator.copyWithId(doc.id).toMap(),
      SetOptions(merge: true),
    );
  }

  Future<List<Mediator>> _fetchMediatorsFromRest() async {
    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/${DefaultFirebaseOptions.web.projectId}/databases/(default)/documents/${AppConstants.mediatorsCollection}',
      {
        'key': DefaultFirebaseOptions.web.apiKey,
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return const <Mediator>[];
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('فشل تحميل الوسطاء من Firestore REST: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = body['documents'] as List<dynamic>? ?? const <dynamic>[];
    final mediators = <Mediator>[];

    for (final document in documents) {
      try {
        final doc = document as Map<String, dynamic>;
        final namePath = doc['name'] as String? ?? '';
        final id = namePath.split('/').isNotEmpty ? namePath.split('/').last : '';
        final fields = doc['fields'] as Map<String, dynamic>? ?? const <String, dynamic>{};
        final mediator = Mediator.fromMap(id, _decodeDocument(fields));
        if (mediator.name.isNotEmpty) mediators.add(mediator);
      } catch (_) {}
    }

    mediators.sort((a, b) => a.name.compareTo(b.name));
    return mediators;
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
}
