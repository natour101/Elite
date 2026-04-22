class AppStats {
  const AppStats({
    this.homeVisits = 0,
    this.shopVisits = 0,
    this.productViews = 0,
    this.cartVisits = 0,
    this.addToCartClicks = 0,
    this.orderRequests = 0,
    this.imagePreviewOpens = 0,
    this.lastViewedProductName,
  });

  final int homeVisits;
  final int shopVisits;
  final int productViews;
  final int cartVisits;
  final int addToCartClicks;
  final int orderRequests;
  final int imagePreviewOpens;
  final String? lastViewedProductName;

  int get totalVisits => homeVisits + shopVisits + cartVisits + productViews;

  AppStats copyWith({
    int? homeVisits,
    int? shopVisits,
    int? productViews,
    int? cartVisits,
    int? addToCartClicks,
    int? orderRequests,
    int? imagePreviewOpens,
    Object? lastViewedProductName = _statsSentinel,
  }) {
    return AppStats(
      homeVisits: homeVisits ?? this.homeVisits,
      shopVisits: shopVisits ?? this.shopVisits,
      productViews: productViews ?? this.productViews,
      cartVisits: cartVisits ?? this.cartVisits,
      addToCartClicks: addToCartClicks ?? this.addToCartClicks,
      orderRequests: orderRequests ?? this.orderRequests,
      imagePreviewOpens: imagePreviewOpens ?? this.imagePreviewOpens,
      lastViewedProductName: lastViewedProductName == _statsSentinel
          ? this.lastViewedProductName
          : lastViewedProductName as String?,
    );
  }
}

const _statsSentinel = Object();
