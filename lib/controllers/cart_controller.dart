import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartController extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

  void addProduct(Product product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      state = [...state, CartItem(product: product, quantity: 1)];
      return;
    }
    final updated = [...state];
    updated[index] = updated[index].copyWith(quantity: updated[index].quantity + 1);
    state = updated;
  }

  void changeQuantity(String productId, int nextQuantity) {
    if (nextQuantity <= 0) {
      removeProduct(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.product.id == productId)
          item.copyWith(quantity: nextQuantity)
        else
          item,
    ];
  }

  void removeProduct(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clear() => state = const [];
}

final cartControllerProvider =
    NotifierProvider<CartController, List<CartItem>>(CartController.new);

final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartControllerProvider).fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      );
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartControllerProvider).fold<double>(
        0,
        (sum, item) => sum + (item.lineTotal ?? 0),
      );
});
