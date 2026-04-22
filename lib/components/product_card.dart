import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/store_controller.dart';
import '../core/theme/app_theme.dart';
import '../models/antique_product.dart';
import '../utils/currency_formatter.dart';
import 'antique_shell.dart';
import 'image_preview_dialog.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({
    super.key,
    required this.product,
  });

  final AntiqueProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isCompact = MediaQuery.sizeOf(context).width < 430;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            onTap: () {
              ref.read(appStatsProvider.notifier).recordImagePreview();
              ImagePreviewDialog.show(
                context,
                imageUrl: product.imageUrl,
                heroTag: 'product-image-${product.id}',
              );
            },
            child: Hero(
              tag: 'product-image-${product.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: AspectRatio(
                  aspectRatio: 1.02,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) {
                        return child;
                      }
                      return const ColoredBox(
                        color: Color(0xFFF0E3D1),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, _, __) {
                      return const ColoredBox(
                        color: Color(0xFFF0E3D1),
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: AppTheme.bronze,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رقم المنتج: ${product.productNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTheme.bronze,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(fontSize: isCompact ? 18 : 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        maxLines: isCompact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        formatPrice(product.price),
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppTheme.wood,
                          fontSize: isCompact ? 22 : 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                ref.read(appStatsProvider.notifier).recordProductView(product.name);
                                context.go('/product/${product.id}');
                              },
                              child: const Text('التفاصيل'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                ref.read(cartProvider.notifier).setProduct(product);
                                ref.read(appStatsProvider.notifier).recordAddToCart(product.name);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تمت إضافة المنتج إلى السلة')),
                                );
                              },
                              child: const Text('إضافة إلى السلة'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
