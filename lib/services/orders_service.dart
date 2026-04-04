import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/app_order.dart';

class OrdersService {
  OrdersService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.ordersCollection);

  Stream<List<AppOrder>> watchOrders() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppOrder.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> placeOrder(AppOrder order) async {
    await _collection.add(order.toMap());
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) {
    return _collection.doc(orderId).set(
      {'status': status},
      SetOptions(merge: true),
    );
  }
}
