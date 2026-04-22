import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/antique_shell.dart';
import '../components/filters_panel.dart';
import '../components/product_grid.dart';
import '../controllers/store_controller.dart';
import '../utils/app_spacing.dart';

class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key});

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appStatsProvider.notifier).recordShopVisit();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final products = ref.watch(filteredProductsProvider);

    return PageFrame(
      child: ListView(
        children: [
          Text('المنتجات', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'تصفح القطع بطريقة أوضح ومتجاوبة مع الهاتف، مع فلترة سريعة حسب النوع والسعر والتصنيف.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          const FiltersPanel(),
          const SizedBox(height: AppSpacing.lg),
          if (catalog.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (products.isEmpty)
            const EmptyStateCard(
              title: 'لا توجد نتائج مطابقة',
              message: 'جرّب إزالة بعض الفلاتر للحصول على نتائج أكثر.',
            )
          else
            ProductGrid(products: products),
        ],
      ),
    );
  }
}
