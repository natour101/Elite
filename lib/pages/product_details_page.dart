import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/antique_shell.dart';
import '../components/image_preview_dialog.dart';
import '../components/whatsapp_order_sheet.dart';
import '../controllers/store_controller.dart';
import '../core/theme/app_theme.dart';
import '../utils/app_spacing.dart';
import '../utils/currency_formatter.dart';

class ProductDetailsPage extends ConsumerStatefulWidget {
  const ProductDetailsPage({
    super.key,
    required this.productId,
  });

  final String productId;

  @override
  ConsumerState<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends ConsumerState<ProductDetailsPage> {
  bool _recorded = false;

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(catalogProvider).valueOrNull ?? const [];
    final product = products.where((item) => item.id == widget.productId).firstOrNull;

    if (product != null && !_recorded) {
      _recorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(appStatsProvider.notifier).recordProductView(product.name);
      });
    }

    return PageFrame(
      child: product == null
          ? const EmptyStateCard(
              title: 'القطعة غير موجودة',
              message: 'ربما تم حذف هذه القطعة أو تغير مسارها داخل المتجر.',
            )
          : ListView(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 920;

                    final image = GestureDetector(
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
                          borderRadius: BorderRadius.circular(30),
                          child: AspectRatio(
                            aspectRatio: wide ? 1 : 1.05,
                            child: Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        ),
                      ),
                    );

                    final details = SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'رقم المنتج: ${product.productNumber}',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.bronze,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _MetaChip(label: product.category),
                              _MetaChip(label: product.era),
                              _MetaChip(label: product.material),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(product.name, style: Theme.of(context).textTheme.displayMedium),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            formatPrice(product.price),
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: AppTheme.wood,
                                  fontSize: 38,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(product.description, style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(height: AppSpacing.lg),
                          _DetailBlock(title: 'قصة القطعة', value: product.story),
                          _DetailBlock(title: 'الأبعاد', value: product.dimensions),
                          _DetailBlock(title: 'الحالة', value: product.condition),
                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ref.read(cartProvider.notifier).setProduct(product);
                                ref.read(appStatsProvider.notifier).recordAddToCart(product.name);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تمت إضافة المنتج إلى السلة')),
                                );
                              },
                              icon: const Icon(Icons.shopping_bag_outlined),
                              label: const Text('إضافة إلى السلة'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ref.read(appStatsProvider.notifier).recordOrderRequest();
                                WhatsAppOrderSheet.showSingle(
                                  context,
                                  product: product,
                                );
                              },
                              icon: const Icon(Icons.chat_rounded),
                              label: const Text('إرسال الطلب'),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: image),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(flex: 6, child: details),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        image,
                        const SizedBox(height: AppSpacing.lg),
                        details,
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E2CF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
