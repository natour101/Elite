import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_order.dart';
import '../services/orders_service.dart';
import 'products_controller.dart';

final ordersServiceProvider = Provider<OrdersService>((ref) {
  return OrdersService(ref.watch(firestoreProvider));
});

final ordersProvider = StreamProvider<List<AppOrder>>((ref) {
  return ref.watch(ordersServiceProvider).watchOrders();
});

class PlaceOrderInput {
  const PlaceOrderInput({
    required this.items,
    required this.mediatorId,
    required this.mediatorCode,
    required this.mediatorName,
    required this.customerName,
    required this.customerPhone,
    this.notes = '',
  });

  final List<OrderItem> items;
  final String mediatorId;
  final String mediatorCode;
  final String mediatorName;
  final String customerName;
  final String customerPhone;
  final String notes;

  AppOrder toOrder() {
    return AppOrder(
      id: '',
      items: items,
      mediatorId: mediatorId,
      mediatorCode: mediatorCode,
      mediatorName: mediatorName,
      createdAt: DateTime.now(),
      status: 'pending',
      customerName: customerName,
      customerPhone: customerPhone,
      notes: notes,
    );
  }
}

class OrdersActionsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> placeOrder(PlaceOrderInput input) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ordersServiceProvider).placeOrder(input.toOrder()),
    );
  }

  Future<void> updateStatus({
    required String orderId,
    required String status,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ordersServiceProvider).updateOrderStatus(
            orderId: orderId,
            status: status,
          ),
    );
  }
}

final ordersActionsControllerProvider =
    AsyncNotifierProvider<OrdersActionsController, void>(
  OrdersActionsController.new,
);
