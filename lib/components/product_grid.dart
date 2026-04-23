import 'package:flutter/material.dart';

import '../models/antique_product.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
  });

  final List<AntiqueProduct> products;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1180 ? 3 : width >= 560 ? 2 : 1;
        final spacing = width >= 960 ? 14.0 : width >= 560 ? 12.0 : 10.0;
        final cardHeight = width >= 960 ? 300.0 : width >= 560 ? 320.0 : 350.0;
        final totalSpacing = spacing * (columns - 1);
        final cardWidth = columns == 1
            ? width
            : ((width - totalSpacing) / columns).clamp(0.0, width).toDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final product in products)
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: ProductCard(product: product),
              ),
          ],
        );
      },
    );
  }
}
