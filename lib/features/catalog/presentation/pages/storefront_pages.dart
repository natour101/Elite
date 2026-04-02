import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state_card.dart';
import '../../../order/presentation/widgets/whatsapp_order_sheet.dart';
import '../controllers/catalog_controller.dart';
import '../widgets/product_card.dart';
import '../widgets/product_visual.dart';
import '../widgets/store_sections.dart';

class StoreShell extends StatelessWidget {
  const StoreShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF050505),
        body: Column(
          children: [
            const StoreHeader(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeroBanner(),
          const SizedBox(height: 28),
          const _SegmentEntryGrid(),
          const SizedBox(height: 32),
          const SectionTitle(title: 'الأكثر مشاهدة'),
          const SizedBox(height: 16),
          products.when(
            data: (items) {
              final featured = items.where((item) => item.isFeatured).take(6).toList();
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: featured.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: Responsive.isDesktop(context)
                      ? 3
                      : Responsive.isTablet(context)
                          ? 2
                          : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: Responsive.isMobile(context) ? 0.84 : 0.76,
                ),
                itemBuilder: (context, index) => ProductCard(product: featured[index]),
              );
            },
            loading: () => const AppLoader(),
            error: (_, __) => const EmptyStateCard(
              title: 'تعذر التحميل',
              message: 'تعذر تحميل المنتجات حاليًا.',
            ),
          ),
          const SizedBox(height: 32),
          const StoreFooter(),
        ],
      ),
    );
  }
}

class ShopPage extends ConsumerWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(filteredProductsProvider);
    final filter = ref.watch(catalogFilterProvider);
    final mobile = Responsive.isMobile(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'المتجر'),
          const SizedBox(height: 18),
          Card(
            color: const Color(0xFF0C0C0C),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: mobile ? double.infinity : 260,
                    child: TextField(
                      onChanged: (value) {
                        ref.read(catalogFilterProvider.notifier).state =
                            filter.copyWith(query: value);
                      },
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText: 'ابحث باسم المنتج أو البرند',
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: const Color(0xFF111111),
                      style: const TextStyle(color: Colors.white),
                      iconEnabledColor: AppTheme.gold,
                      value: filter.segment,
                      items: const ['الكل', 'رجالي', 'ستاتي', 'أنتيكا']
                          .map((segment) => DropdownMenuItem(
                                value: segment,
                                child: Text(segment),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        ref.read(catalogFilterProvider.notifier).state =
                            filter.copyWith(segment: value);
                      },
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: const Color(0xFF111111),
                      style: const TextStyle(color: Colors.white),
                      iconEnabledColor: AppTheme.gold,
                      value: filter.category,
                      items: const ['الكل', 'عطور', 'ساعات', 'ملابس', 'شوزات']
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        ref.read(catalogFilterProvider.notifier).state =
                            filter.copyWith(category: value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return const EmptyStateCard(
                  title: 'لا توجد نتائج',
                  message: 'جرّب تغيير الفلاتر.',
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: Responsive.isDesktop(context)
                      ? 3
                      : Responsive.isTablet(context)
                          ? 2
                          : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: Responsive.isMobile(context) ? 0.84 : 0.76,
                ),
                itemBuilder: (context, index) => ProductCard(product: products[index]),
              );
            },
            loading: () => const AppLoader(),
            error: (_, __) => const EmptyStateCard(
              title: 'تعذر التحميل',
              message: 'تعذر تحميل المنتجات حاليًا.',
            ),
          ),
          const SizedBox(height: 26),
          const StoreFooter(),
        ],
      ),
    );
  }
}

class SegmentPage extends ConsumerStatefulWidget {
  const SegmentPage({
    super.key,
    required this.segmentSlug,
  });

  final String segmentSlug;

  @override
  ConsumerState<SegmentPage> createState() => _SegmentPageState();
}

class _SegmentPageState extends ConsumerState<SegmentPage> {
  String selectedCategory = 'الكل';

  @override
  Widget build(BuildContext context) {
    final segment = switch (widget.segmentSlug) {
      'women' => 'ستاتي',
      'antika' => 'أنتيكا',
      _ => 'رجالي',
    };
    final productsAsync = ref.watch(productsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: segment),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final category in const ['الكل', 'عطور', 'ساعات', 'ملابس', 'شوزات'])
                ChoiceChip(
                  label: Text(category),
                  selected: selectedCategory == category,
                  labelStyle: TextStyle(
                    color: selectedCategory == category
                        ? AppTheme.black
                        : Colors.white,
                  ),
                  selectedColor: AppTheme.gold,
                  backgroundColor: const Color(0xFF161616),
                  onSelected: (_) {
                    setState(() => selectedCategory = category);
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          productsAsync.when(
            data: (products) {
              final segmentProducts = products.where((item) {
                final sameSegment = item.segment == segment;
                final sameCategory =
                    selectedCategory == 'الكل' || item.category == selectedCategory;
                return sameSegment && sameCategory;
              }).toList();

              if (segmentProducts.isEmpty) {
                return const EmptyStateCard(
                  title: 'لا توجد منتجات',
                  message: 'سيتم إضافة منتجات لهذا القسم قريبًا.',
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: segmentProducts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: Responsive.isDesktop(context)
                      ? 3
                      : Responsive.isTablet(context)
                          ? 2
                          : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: Responsive.isMobile(context) ? 0.84 : 0.76,
                ),
                itemBuilder: (context, index) =>
                    ProductCard(product: segmentProducts[index]),
              );
            },
            loading: () => const AppLoader(),
            error: (_, __) => const EmptyStateCard(
              title: 'تعذر التحميل',
              message: 'تعذر تحميل المنتجات حاليًا.',
            ),
          ),
          const SizedBox(height: 28),
          const StoreFooter(),
        ],
      ),
    );
  }
}

class ProductDetailsPage extends ConsumerWidget {
  const ProductDetailsPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    return productsAsync.when(
      data: (products) {
        final product = products.firstWhere(
          (item) => item.id == productId,
          orElse: () => products.first,
        );
        final similar = products
            .where((item) => item.category == product.category && item.id != product.id)
            .take(3)
            .toList();
        final price = NumberFormat.currency(
          locale: 'ar',
          symbol: 'JOD ',
          decimalDigits: 0,
        ).format(product.price);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  SizedBox(
                    width: Responsive.isDesktop(context)
                        ? 520
                        : MediaQuery.sizeOf(context).width - 40,
                    child: ProductVisual(product: product, height: 420, radius: 30),
                  ),
                  SizedBox(
                    width: Responsive.isDesktop(context) ? 420 : double.infinity,
                    child: Card(
                      color: const Color(0xFF0C0C0C),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.category,
                                style: const TextStyle(
                                  color: AppTheme.gold,
                                  fontWeight: FontWeight.w700,
                                )),
                            const SizedBox(height: 8),
                            Text(
                              product.segment,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 6),
                            Text(product.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    )),
                            const SizedBox(height: 8),
                            Text('رقم المنتج: ${product.productNumber}',
                                style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 6),
                            Text('البرند: ${product.brand}',
                                style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 6),
                            Text('التاجر: ${product.sellerName}',
                                style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 6),
                            Text('هاتف التاجر: ${product.sellerPhone}',
                                style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 14),
                            Text(price,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.gold,
                                    )),
                            const SizedBox(height: 14),
                            Text(product.description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: Colors.white.withOpacity(0.78))),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: product.isAvailable
                                    ? const Color(0xFFEAF7ED)
                                    : const Color(0xFFFCEDEA),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(product.isAvailable
                                  ? 'متوفر في المخزون (${product.stock})'
                                  : 'غير متوفر'),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: const Color(0xFF0C0C0C),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(28),
                                    ),
                                  ),
                                  builder: (_) => WhatsAppOrderSheet(product: product),
                                ),
                                icon: const Icon(Icons.chat_outlined),
                                label: const Text('طلب عبر واتساب'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const SectionTitle(title: 'منتجات مشابهة'),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: similar.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: Responsive.isDesktop(context) ? 3 : 1,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) => ProductCard(product: similar[index]),
              ),
              const SizedBox(height: 26),
              const StoreFooter(),
            ],
          ),
        );
      },
      loading: () => const AppLoader(),
      error: (_, __) => const EmptyStateCard(
        title: 'المنتج غير متاح',
        message: 'تعذر عرض تفاصيل المنتج حاليًا.',
      ),
    );
  }
}

class SimpleContentPage extends StatelessWidget {
  const SimpleContentPage({
    super.key,
    required this.title,
    required this.sections,
  });

  final String title;
  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: title),
          const SizedBox(height: 20),
          for (final section in sections) ...[
            Card(
              color: const Color(0xFF0C0C0C),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.$1,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.gold,
                            )),
                    const SizedBox(height: 10),
                    Text(
                      section.$2,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.white.withOpacity(0.78)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const StoreFooter(),
        ],
      ),
    );
  }
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimpleContentPage(
      title: 'تواصل معنا',
      sections: [
        ('رقم التواصل', '0780045351'),
        ('واتساب', '0795422974'),
      ],
    );
  }
}

class _SegmentEntryGrid extends StatelessWidget {
  const _SegmentEntryGrid();

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('رجالي', '/segment/men'),
      ('ستاتي', '/segment/women'),
      ('أنتيكا', '/segment/antika'),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final item in items)
          _SegmentEntryCard(title: item.$1, route: item.$2),
      ],
    );
  }
}

class _SegmentEntryCard extends StatelessWidget {
  const _SegmentEntryCard({
    required this.title,
    required this.route,
  });

  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    final width = Responsive.isMobile(context)
        ? MediaQuery.sizeOf(context).width - 40
        : 250.0;

    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () => context.go(route),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0C0C0C),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.gold.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppTheme.gold),
            ),
          ],
        ),
      ),
    );
  }
}
