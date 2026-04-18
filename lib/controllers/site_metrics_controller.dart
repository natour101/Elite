import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/site_metrics_service.dart';
import 'products_controller.dart';

final siteMetricsServiceProvider = Provider<SiteMetricsService>((ref) {
  return SiteMetricsService(ref.watch(firestoreProvider));
});

class SiteMetricsController extends AsyncNotifier<SiteMetrics> {
  @override
  Future<SiteMetrics> build() async {
    final sales = ref.watch(salesCountProvider);
    return ref
        .read(siteMetricsServiceProvider)
        .registerVisitAndFetchCount(sales: sales);
  }

  Future<void> refresh() async {
    final sales = ref.read(salesCountProvider);
    state = await AsyncValue.guard(
      () => ref.read(siteMetricsServiceProvider).fetchMetrics(sales: sales),
    );
  }
}

final siteMetricsProvider =
    AsyncNotifierProvider<SiteMetricsController, SiteMetrics>(
  SiteMetricsController.new,
);

final siteVisitsProvider = Provider<int>((ref) {
  return ref.watch(siteMetricsProvider).valueOrNull?.totalVisits ?? 0;
});

final todayVisitsProvider = Provider<int>((ref) {
  return ref.watch(siteMetricsProvider).valueOrNull?.todayVisits ?? 0;
});

final salesCountProvider = Provider<int>((ref) {
  final products = ref.watch(productsProvider).valueOrNull ?? const [];
  return products.where((product) => product.isSold).length;
});
