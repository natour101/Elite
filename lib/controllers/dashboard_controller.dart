import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_order.dart';
import '../models/mediator.dart';
import '../models/mediators_stats.dart';
import '../models/product.dart';
import 'mediators_controller.dart';
import 'orders_controller.dart';
import 'products_controller.dart';

final mediatorStatsProvider = Provider<AsyncValue<List<MediatorStats>>>((ref) {
  final mediatorsAsync = ref.watch(mediatorsProvider);
  final ordersAsync = ref.watch(ordersProvider);

  return mediatorsAsync.whenData((mediators) {
    final orders = ordersAsync.valueOrNull ?? const <AppOrder>[];
    return mediators
        .map((mediator) => MediatorStats.fromOrders(mediator, orders))
        .toList();
  });
});

final dashboardStatsProvider = Provider<Map<String, num>>((ref) {
  final products = ref.watch(productsProvider).valueOrNull ?? const <Product>[];
  final orders = ref.watch(ordersProvider).valueOrNull ?? const <AppOrder>[];
  final mediators = ref.watch(mediatorsProvider).valueOrNull ?? const <MediatorProfile>[];

  return {
    'products': products.length,
    'orders': orders.length,
    'mediators': mediators.length,
    'sales': orders.fold<double>(0, (sum, order) => sum + order.totalAmount),
  };
});
