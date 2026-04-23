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
    return SectionCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useHorizontalCard =
              constraints.maxWidth > 380 && constraints.maxHeight <= 340;

          if (useHorizontalCard) {
            return _HorizontalProductCard(product: product);
          }

          return _VerticalProductCard(product: product);
        },
      ),
    );
  }
}

class _VerticalProductCard extends ConsumerWidget {
  const _VerticalProductCard({required this.product});

  final AntiqueProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        SizedBox(
          height: 120,
          width: double.infinity,
          child: _ProductImage(product: product),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
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
                  style: textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    product.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(height: 1.45),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatPrice(product.price),
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppTheme.wood,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                _CardActions(product: product),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HorizontalProductCard extends ConsumerWidget {
  const _HorizontalProductCard({required this.product});

  final AntiqueProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        SizedBox(
          width: 176,
          height: double.infinity,
          child: _ProductImage(product: product),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
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
                const SizedBox(height: 6),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    product.description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatPrice(product.price),
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppTheme.wood,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 10),
                _CardActions(product: product, compact: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductImage extends ConsumerWidget {
  const _ProductImage({required this.product});

  final AntiqueProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: const Color(0xFFF0E3D1),
      child: InkWell(
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
          child: Image.network(
            product.imageUrl,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, _, __) {
              return const Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppTheme.bronze,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CardActions extends ConsumerWidget {
  const _CardActions({
    required this.product,
    this.compact = false,
  });

  final AntiqueProduct product;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (compact) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                ref.read(appStatsProvider.notifier).recordProductView(product.name);
                context.go('/product/${product.id}');
              },
              child: const Text('التفاصيل'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
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
      );
    }

    return Column(
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
    );
  }
}
