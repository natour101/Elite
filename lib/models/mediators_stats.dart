import 'app_order.dart';
import 'mediator.dart';

class MediatorStats {
  const MediatorStats({
    required this.mediator,
    required this.ordersCount,
    required this.productsSold,
    required this.totalSales,
  });

  final MediatorProfile mediator;
  final int ordersCount;
  final int productsSold;
  final double totalSales;

  factory MediatorStats.fromOrders(
    MediatorProfile mediator,
    List<AppOrder> orders,
  ) {
    final related = orders.where((order) => order.mediatorId == mediator.id).toList();
    final productsSold = related.fold<int>(
      0,
      (sum, order) => sum + order.totalQuantity,
    );
    final totalSales = related.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );

    return MediatorStats(
      mediator: mediator,
      ordersCount: related.length,
      productsSold: productsSold,
      totalSales: totalSales,
    );
  }
}
