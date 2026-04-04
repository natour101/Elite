import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elite_luxury_store/screens/admin/admin_screens.dart';
import 'package:elite_luxury_store/screens/store/store_screens.dart';

void main() {
  test('core screens instantiate', () {
    expect(const StoreHomeScreen(), isA<Widget>());
    expect(const CartScreen(), isA<Widget>());
    expect(const CheckoutScreen(), isA<Widget>());
    expect(const AdminLoginScreen(), isA<Widget>());
    expect(const AdminDashboardScreen(), isA<Widget>());
    expect(const AdminProductsScreen(), isA<Widget>());
    expect(const AdminMediatorsScreen(), isA<Widget>());
    expect(const AdminOrdersScreen(), isA<Widget>());
  });
}
