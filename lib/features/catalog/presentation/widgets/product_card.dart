import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../core/theme/app_theme.dart';
import '../../domain/product.dart';
import 'product_visual.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final price = NumberFormat.currency(
      locale: 'ar',
      symbol: 'JOD ',
      decimalDigits: 0,
    ).format(product.price);

    return Card(
      color: const Color(0xFF0C0C0C),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/product/${product.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ProductVisual(product: product, height: 210, radius: 22),
                  if (product.isFeatured)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.softWhite,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('مميز'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${product.segment} • ${product.category}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.gold, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(product.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      )),
              const SizedBox(height: 6),
              Text(product.brand,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white.withOpacity(0.68))),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    price,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.gold,
                        ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: AppTheme.gold),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
