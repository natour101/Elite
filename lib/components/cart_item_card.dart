import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/store_controller.dart';
import '../models/cart_item.dart';
import '../utils/currency_formatter.dart';
import 'antique_shell.dart';

class CartItemCard extends ConsumerWidget {
  const CartItemCard({
    super.key,
    required this.item,
  });

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);

    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              item.product.imageUrl,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) => const SizedBox(
                width: 96,
                height: 96,
                child: ColoredBox(
                  color: Color(0xFFF0E3D1),
                  child: Icon(Icons.image_outlined),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'رقم المنتج: ${item.product.productNumber}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(item.product.category, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 10),
                Text(
                  formatPrice(item.totalPrice),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: notifier.clear,
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
  }
}
