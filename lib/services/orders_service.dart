import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/polling_stream.dart';
import '../models/app_order.dart';

class OrdersService {
  OrdersService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.ordersCollection);

  Stream<List<AppOrder>> watchOrders() {
    return pollingListStream(_fetchOrders);
  }

  Future<List<AppOrder>> _fetchOrders() async {
    final snapshot = await _collection.get();
    final orders = snapshot.docs
        .map((doc) => AppOrder.fromMap(doc.id, doc.data()))
        .toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
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
