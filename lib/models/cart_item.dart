import 'antique_product.dart';

class CartItem {
  const CartItem({
    required this.product,
  });

  final AntiqueProduct product;

  double get totalPrice => product.price;
}
