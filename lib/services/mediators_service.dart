import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/mediator.dart';

class DuplicateMediatorCodeException implements Exception {
  const DuplicateMediatorCodeException(this.code);

  final String code;

  @override
  String toString() => 'Mediator code already exists: $code';
}

class MediatorsService {
  MediatorsService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _mediators =>
      _firestore.collection(AppConstants.mediatorsCollection);

  CollectionReference<Map<String, dynamic>> get _codes =>
      _firestore.collection(AppConstants.mediatorCodesCollection);

  Stream<List<MediatorProfile>> watchMediators() {
    return _mediators
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MediatorProfile.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> saveMediator(MediatorProfile mediator) async {
    final normalizedCode = mediator.code.trim().toUpperCase();
    if (normalizedCode.length != 4) {
      throw ArgumentError('يجب أن يكون كود الوسيط مكونًا من 4 أحرف.');
    }

    final mediatorData = mediator.toMap()..['code'] = normalizedCode;

    if (mediator.id.isEmpty) {
      final newDoc = _mediators.doc();
      final codeRef = _codes.doc(normalizedCode);
      await _firestore.runTransaction((transaction) async {
        final codeSnapshot = await transaction.get(codeRef);
        if (codeSnapshot.exists) {
          throw DuplicateMediatorCodeException(normalizedCode);
        }

        transaction.set(newDoc, mediatorData);
        transaction.set(codeRef, {
          'mediatorId': newDoc.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      return;
    }

    final mediatorRef = _mediators.doc(mediator.id);
    await _firestore.runTransaction((transaction) async {
      final mediatorSnapshot = await transaction.get(mediatorRef);
      final currentCode =
          (mediatorSnapshot.data()?['code'] as String? ?? '').trim().toUpperCase();

      if (currentCode == normalizedCode) {
        transaction.set(mediatorRef, mediatorData, SetOptions(merge: true));
        return;
      }

      final nextCodeRef = _codes.doc(normalizedCode);
      final nextCodeSnapshot = await transaction.get(nextCodeRef);
      if (nextCodeSnapshot.exists) {
        throw DuplicateMediatorCodeException(normalizedCode);
      }

      transaction.set(mediatorRef, mediatorData, SetOptions(merge: true));
      transaction.set(nextCodeRef, {
        'mediatorId': mediator.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (currentCode.isNotEmpty) {
        transaction.delete(_codes.doc(currentCode));
      }
    });
  }

  Future<void> deleteMediator(MediatorProfile mediator) async {
    await _firestore.runTransaction((transaction) async {
      transaction.delete(_mediators.doc(mediator.id));
      transaction.delete(_codes.doc(mediator.code.trim().toUpperCase()));
    });
  }
}
