class DashboardSummary {
  const DashboardSummary({
    required this.totalProducts,
    required this.pendingProducts,
    required this.approvedProducts,
    required this.availableProducts,
    required this.reservedProducts,
    required this.soldProducts,
    required this.totalMediators,
    required this.totalVisits,
    required this.todayVisits,
    required this.grossSales,
    required this.companySales,
    required this.appCommissions,
    required this.totalAppProfit,
    required this.totalMediatorBalances,
    required this.totalListingCommissions,
    required this.totalSellingCommissions,
    required this.mediatorProfits,
    required this.mediatorBalances,
    required this.mediatorListingCommissions,
    required this.mediatorSellingCommissions,
  });

  final int totalProducts;
  final int pendingProducts;
  final int approvedProducts;
  final int availableProducts;
  final int reservedProducts;
  final int soldProducts;
  final int totalMediators;
  final int totalVisits;
  final int todayVisits;
  final double grossSales;
  final double companySales;
  final double appCommissions;
  final double totalAppProfit;
  final double totalMediatorBalances;
  final double totalListingCommissions;
  final double totalSellingCommissions;
  final Map<String, double> mediatorProfits;
  final Map<String, double> mediatorBalances;
  final Map<String, double> mediatorListingCommissions;
  final Map<String, double> mediatorSellingCommissions;
}
