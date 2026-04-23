import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/antique_shell.dart';
import '../components/hero_banner.dart';
import '../components/product_grid.dart';
import '../controllers/store_controller.dart';
import '../utils/app_spacing.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appStatsProvider.notifier).recordHomeVisit();
    });
  }

  @override
  Widget build(BuildContext context) {
    final featured = ref.watch(featuredProductsProvider);
    final catalog = ref.watch(catalogProvider);

    return PageFrame(
      child: ListView(
        children: [
          const HeroBanner(),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 460;

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'منتجات مختارة',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: () => context.go('/shop'),
                      child: const Text('عرض الكل'),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      'منتجات مختارة',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => context.go('/shop'),
                    child: const Text('عرض الكل'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (catalog.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (featured.isEmpty)
            EmptyStateCard(
              title: 'لا توجد منتجات حاليًا',
              message: 'أضف قطع أنتيكا جديدة لتظهر هنا مباشرة.',
              actionLabel: 'الانتقال للمتجر',
              onAction: () => context.go('/shop'),
            )
          else
            ProductGrid(products: featured),
        ],
      ),
    );
  }
}
