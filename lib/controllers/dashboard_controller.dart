import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_summary.dart';
import '../models/mediator.dart';
import '../models/portal_session.dart';
import '../models/product.dart';
import 'mediators_controller.dart';
import 'portal_session_controller.dart';
import 'products_controller.dart';
import 'site_metrics_controller.dart';

final dashboardSummaryProvider = Provider<DashboardSummary>((ref) {
  final products = ref.watch(productsProvider).valueOrNull ?? const <Product>[];
  final mediators =
      ref.watch(mediatorsProvider).valueOrNull ?? const <Mediator>[];
  final metrics = ref.watch(siteMetricsProvider).valueOrNull;
  final soldProducts = products.where((product) => product.isSold).toList();

  final profits = <String, double>{};
  final balances = <String, double>{};
  final listingCommissions = <String, double>{};
  final sellingCommissions = <String, double>{};

  double grossSales = 0;
  double companySales = 0;
  double appCommissions = 0;
  double totalMediatorBalances = 0;
  double totalListingCommissions = 0;
  double totalSellingCommissions = 0;

  for (final product in soldProducts) {
    grossSales += product.effectivePrice;
    companySales += product.companyShare;
    totalSellingCommissions += product.sellingShare;

    if (product.soldByMediatorCode.isNotEmpty) {
      sellingCommissions.update(
        product.soldByMediatorCode,
        (value) => value + product.sellingShare,
        ifAbsent: () => product.sellingShare,
      );
      profits.update(
        product.soldByMediatorCode,
        (value) => value + product.sellingShare,
        ifAbsent: () => product.sellingShare,
      );
      balances.update(
        product.soldByMediatorCode,
        (value) => value + product.sellingShare,
        ifAbsent: () => product.sellingShare,
      );
      totalMediatorBalances += product.sellingShare;
    } else {
      appCommissions += product.sellingShare;
    }
  }

  return DashboardSummary(
    totalProducts: products.length,
    pendingProducts:
        products.where((product) => product.isPendingApproval).length,
    approvedProducts: products.where((product) => product.isApproved).length,
    availableProducts: products.where((product) => product.isAvailable).length,
    reservedProducts: products.where((product) => product.isReserved).length,
    soldProducts: soldProducts.length,
    totalMediators: mediators.where((mediator) => mediator.isActive).length,
    totalVisits: metrics?.totalVisits ?? 0,
    todayVisits: metrics?.todayVisits ?? 0,
    grossSales: grossSales,
    companySales: companySales,
    appCommissions: appCommissions,
    totalAppProfit: companySales + appCommissions,
    totalMediatorBalances: totalMediatorBalances,
    totalListingCommissions: totalListingCommissions,
    totalSellingCommissions: totalSellingCommissions,
    mediatorProfits: profits,
    mediatorBalances: balances,
    mediatorListingCommissions: listingCommissions,
    mediatorSellingCommissions: sellingCommissions,
  );
});

final portalCatalogProductsProvider = Provider<List<Product>>((ref) {
  final session = ref.watch(portalSessionProvider).valueOrNull;
  final products = ref.watch(productsProvider).valueOrNull ?? const <Product>[];

  if (session == null || session.isAdmin) return products;

  return products
      .where((product) => product.isApproved && !product.isSold)
      .toList();
});

final portalSalesProductsProvider = Provider<List<Product>>((ref) {
  final session = ref.watch(portalSessionProvider).valueOrNull;
  final products = ref.watch(productsProvider).valueOrNull ?? const <Product>[];

  if (session == null || session.isAdmin) {
    return products.where((product) => product.isSold).toList();
  }

  final code = session.mediator?.code.toUpperCase() ?? '';
  return products.where((product) => product.soldByMediatorCode == code).toList();
});

final portalSummaryProvider = Provider<DashboardSummary>((ref) {
  final fullSummary = ref.watch(dashboardSummaryProvider);
  final session = ref.watch(portalSessionProvider).valueOrNull;

  if (session == null || session.role == PortalRole.admin) {
    return fullSummary;
  }

  final code = session.mediator?.code.toUpperCase() ?? '';
  final visibleProducts = ref.watch(portalCatalogProductsProvider);
  final soldProducts = ref.watch(portalSalesProductsProvider);

  double grossSales = 0;
  double companySales = 0;
  for (final product in soldProducts) {
    grossSales += product.effectivePrice;
    companySales += product.companyShare;
  }

  return DashboardSummary(
    totalProducts: visibleProducts.length,
    pendingProducts: 0,
    approvedProducts: visibleProducts.where((product) => product.isApproved).length,
    availableProducts: visibleProducts.where((product) => product.isAvailable).length,
    reservedProducts: visibleProducts.where((product) => product.isReserved).length,
    soldProducts: soldProducts.length,
    totalMediators: 1,
    totalVisits: fullSummary.totalVisits,
    todayVisits: fullSummary.todayVisits,
    grossSales: grossSales,
    companySales: companySales,
    appCommissions: 0,
    totalAppProfit: fullSummary.mediatorProfits[code] ?? 0,
    totalMediatorBalances: fullSummary.mediatorBalances[code] ?? 0,
    totalListingCommissions:
        fullSummary.mediatorListingCommissions[code] ?? 0,
    totalSellingCommissions:
        fullSummary.mediatorSellingCommissions[code] ?? 0,
    mediatorProfits: {code: fullSummary.mediatorProfits[code] ?? 0},
    mediatorBalances: {code: fullSummary.mediatorBalances[code] ?? 0},
    mediatorListingCommissions: {
      code: fullSummary.mediatorListingCommissions[code] ?? 0,
    },
    mediatorSellingCommissions: {
      code: fullSummary.mediatorSellingCommissions[code] ?? 0,
    },
  );
});
