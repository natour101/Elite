import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/antique_shell.dart';
import '../controllers/store_controller.dart';
import '../utils/app_spacing.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(appStatsProvider);

    return PageFrame(
      child: ListView(
        children: [
          Text('الإحصائيات', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'ملخص سريع لتفاعل المستخدمين داخل التطبيق.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(title: 'إجمالي الزيارات', value: '${stats.totalVisits}'),
              _StatCard(title: 'زيارات الرئيسية', value: '${stats.homeVisits}'),
              _StatCard(title: 'زيارات المتجر', value: '${stats.shopVisits}'),
              _StatCard(title: 'مشاهدات المنتج', value: '${stats.productViews}'),
              _StatCard(title: 'زيارات السلة', value: '${stats.cartVisits}'),
              _StatCard(title: 'إضافات السلة', value: '${stats.addToCartClicks}'),
              _StatCard(title: 'طلبات واتساب', value: '${stats.orderRequests}'),
              _StatCard(title: 'تكبير الصور', value: '${stats.imagePreviewOpens}'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('آخر قطعة تم التفاعل معها', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  stats.lastViewedProductName ?? 'لا يوجد تفاعل مسجل بعد.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: Theme.of(context).textTheme.displayMedium),
          ],
        ),
      ),
    );
  }
}
