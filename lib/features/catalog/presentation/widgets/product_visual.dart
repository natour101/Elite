import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/product.dart';

class ProductVisual extends StatelessWidget {
  const ProductVisual({
    super.key,
    required this.product,
    this.height = 220,
    this.radius = 24,
  });

  final Product product;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isWatch = product.category == 'ساعات';
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: isWatch
              ? const [AppTheme.black, Color(0xFF37312A)]
              : const [Color(0xFFF5E8C8), AppTheme.gold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isWatch ? Icons.watch_outlined : Icons.local_mall_outlined,
              color: isWatch ? AppTheme.gold : AppTheme.black,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              product.brand,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isWatch ? Colors.white : AppTheme.black,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              product.image,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        (isWatch ? Colors.white : AppTheme.black).withOpacity(0.65),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
